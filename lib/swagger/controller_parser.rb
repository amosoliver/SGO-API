# frozen_string_literal: true
# lib/swagger/controller_parser.rb
#
# Escaneia app/controllers/api/**/*.rb e extrai por controller:
#
#  Ações CRUD padrão (index, show, create, update, destroy)
#  Ações customizadas (importar, upload_arquivo, etc.)
#  params.permit por ação — direto no corpo ou via método privado referenciado
#  Campos de arquivo (format: binary) detectados pelo nome e pelo corpo da ação
#  Detecção de multipart/form-data (Roo::, .original_filename, params[:arquivo], etc.)
#  Padrão Model.column_names.reject{}.permit(*permitted, :extra_field)
#  Método HTTP de ações customizadas (heurística por nome + @swagger_method_X)
#  Metadados de documentação via comentários @swagger_*

module Swagger
  class ControllerParser
    CRUD_ACTIONS = %w[index show create update destroy].freeze

    # Heurística nome → HTTP para ações customizadas
    CUSTOM_HTTP_HINTS = {
      /\A(import|importar|upload|enviar|processar|executar|sincronizar|
          gerar|calcular|acionar|criar|cadastrar)/x => :post,
      /\A(download|exportar|relatorio|report|preview|visualizar|listar|buscar)/x => :get,
      /\A(ativar|desativar|aprovar|rejeitar|cancelar|bloquear|
          desbloquear|definir|remover|atualizar|alterar)/x => :patch,
      /\Adelete_/ => :delete
    }.freeze

    # Tipo OpenAPI pelo nome do campo
    FIELD_TYPE_MAP = {
      /_id\z/                                          => { type: "integer", format: "int64" },
      /\Aemail|_email\z/                               => { type: "string",  format: "email" },
      /password|senha/                                 => { type: "string",  format: "password" },
      /\Acpf\z|\Acnpj\z|cpf_cnpj/                     => { type: "string" },
      /\Adata_|\A.*_at\z|data_nascimento/              => { type: "string",  format: "date" },
      /valor|preco|percentual|taxa/                    => { type: "number",  format: "double" },
      /\Aativo\z|proprio|embutido|possui|admin|bloqueado/ => { type: "boolean" },
      /nivel|numero|tentativas/                        => { type: "integer" }
    }.freeze

    # Indicadores de upload no corpo de uma ação ou nos seus params privados
    MULTIPART_INDICATORS = [
      /\.original_filename\b/,
      /\.content_type\b/,
      /\.read\b/,
      /Roo::/,
      /ActionDispatch.*UploadedFile/,
      /CarrierWave|Shrine|ActiveStorage\.attach/,
      /params\[:arquivo\]/,
      /params\[:file\]/,
      /params\[:anexo\]/,
      /params\[:imagem\]/,
      /params\[:foto\]/,
      /\.tempfile\b/
    ].freeze

    # Padrões de campo de arquivo pelo nome (excluindo _url)
    # Inclui palavras exatas como :anexo, :arquivo, :file, :imagem, :foto
    FILE_FIELD_PATTERN = /
      \Aimagem_|\Afoto_|\Aanexo_|\Adocumento_|\Aplanilha_|  # prefixo
      _imagem\z|_foto\z|_anexo\z|_arquivo\z|               # sufixo
      \Aarquivo\z|\Afile\z|_file\z|                         # exatos
      \Aanexo\z|\Aimagem\z|\Afoto\z|                        # exatos pt-br
      \Alogo\z|\Aavatar\z|\Athumbnail\z|\Acover\z|          # imagens comuns
      \Adocumento\z|\Aplanilha\z|\Arelatorio\z              # docs
    /x.freeze

    attr_reader :controllers

    def initialize(paths = nil)
      @search_paths = Array(paths || [Rails.root.join("app", "controllers", "api")])
      @controllers  = []
      @routes_map   = parse_routes_file!
      parse!
    end

    def to_resources
      @controllers
    end

    # Tipo OpenAPI para um campo pelo nome — usado pelo OpenapiBuilder
    def self.infer_field_type(field_name)
      FIELD_TYPE_MAP.each do |pattern, type_def|
        return type_def.dup if field_name.to_s.match?(pattern)
      end
      { type: "string" }
    end

    private

    # ─────────────────────────────────────────────────────── parse ──

    def parse!
      @search_paths.each do |base|
        Dir.glob(File.join(base.to_s, "**", "*.rb")).sort.each do |file|
          info = extract_info(file, File.read(file))
          @controllers << info if info
        end
      end
    end

    def extract_info(file, content)
      klass_match = content.match(/class\s+([\w:]+Controller)/)
      return nil unless klass_match

      klass = klass_match[1]
      return nil unless klass.start_with?("Api::")

      version       = extract_version(klass)
      resource_name = File.basename(file, ".rb").sub(/_controller$/, "")
      model_name    = infer_model_name(resource_name)

      public_body, private_body = split_public_private(content)
      public_actions = scan_public_actions(public_body)
      return nil if public_actions.empty?

      # Ações que pulam autenticação (skip_before_action :authenticate_*)
      unauthenticated_actions = extract_unauthenticated_actions(content)

      private_permit_map = extract_private_permit_methods(private_body)
      actions_meta       = build_actions_meta(public_actions, public_body, private_permit_map,
                                              unauthenticated_actions)

      crud   = public_actions & CRUD_ACTIONS
      custom = public_actions - CRUD_ACTIONS

      {
        controller_class:       klass,
        resource:               resource_name,
        model:                  model_name,
        version:                version,
        actions:                crud,
        custom_actions:         build_custom_actions(custom, content, actions_meta),
        actions_meta:           actions_meta,
        unauthenticated_actions: unauthenticated_actions,
        extra_meta:             extract_swagger_meta(content)
      }
    end

    # ────────────────────────────────────── público / privado ──

    def split_public_private(content)
      idx = content.index(/^\s+private\b/)
      idx ? [content[0...idx], content[idx..]] : [content, ""]
    end

    def scan_public_actions(body)
      body.scan(/^\s+def\s+(\w+)\b/).flatten.uniq
    end

    # ──────────────────────── permit de métodos privados ──

    # Retorna { "g_produto_params" => { fields:[], file_fields:[], uses_column_names:, column_names_model: } }
    def extract_private_permit_methods(private_body)
      result = {}
      private_body.scan(/def\s+(\w+)(.*?)(?=\n\s+def\s|\z)/m) do |mname, mbody|
        meta = extract_permit_meta(mbody)
        result[mname] = meta if meta[:fields].any? || meta[:uses_column_names]
      end
      result
    end

    def extract_permit_meta(body)
      raw_fields        = extract_permit_fields(body)
      uses_column_names = body.match?(/\.column_names\b/)
      model_name        = nil
      extra_fields      = []

      # extract_permit_fields returns Hash when array fields found, Array otherwise
      if raw_fields.is_a?(Hash)
        fields       = raw_fields[:scalar_fields] || []
        array_fields = raw_fields[:array_fields]  || []
      else
        fields       = raw_fields
        array_fields = []
      end

      if uses_column_names
        m = body.match(/(\w+)\.column_names/)
        model_name   = m[1] if m
        extra_fields = extract_extra_fields_after_splat(body)
        fields       = (fields | extra_fields)
      end

      file_fields = detect_file_fields_by_name(fields) | detect_file_fields_by_access(body)

      {
        fields:             fields,
        array_fields:       array_fields,
        file_fields:        file_fields,
        extra_fields:       extra_fields,
        uses_column_names:  uses_column_names,
        column_names_model: model_name
      }
    end

    # Campos listados explicitamente após *permitted no permit:
    # permit(*permitted.map(&:to_sym), :imagem_produto)  →  ["imagem_produto"]
    def extract_extra_fields_after_splat(body)
      extras = []
      body.scan(/\.permit\((?:[^)]*\*\w+[^,)]*),\s*(.*?)\)/m) do |after|
        after.first.to_s.scan(/[:"'](\w+)["']?/).flatten.each { |f| extras << f unless f.empty? }
      end
      extras.uniq
    end

    # ──────────────────────────────── metadados por ação ──

    def build_actions_meta(actions, public_body, private_permit_map, unauthenticated_actions = [])
      meta = {}
      actions.each do |action|
        body = extract_action_body(action, public_body)
        next unless body

        permit_meta     = resolve_permit_meta(body, private_permit_map)
        body_multipart  = detect_multipart(body)
        all_file_fields = (permit_meta[:file_fields] + detect_file_fields_by_access(body)).uniq

        # Também detecta multipart se qualquer campo do permit for arquivo
        # Isso captura casos como documento_params com :anexo mesmo sem acesso direto no body
        permit_has_file = permit_meta[:fields].any? { |f| file_field_by_name?(f) }
        is_multipart    = body_multipart || all_file_fields.any? || permit_has_file

        # Garante que campos de arquivo do permit entrem em all_file_fields
        if permit_has_file
          permit_files = permit_meta[:fields].select { |f| file_field_by_name?(f) }
          all_file_fields = (all_file_fields + permit_files).uniq
        end

        meta[action] = {
          permit_fields:      permit_meta[:fields],
          array_fields:       permit_meta[:array_fields] || [],
          file_fields:        all_file_fields,
          extra_fields:       permit_meta[:extra_fields] || [],
          uses_column_names:  permit_meta[:uses_column_names],
          column_names_model: permit_meta[:column_names_model],
          grouped_params:     permit_meta[:grouped_params],
          is_multipart:       is_multipart,
          http_method:        crud_http_method(action),
          uses_service:       body.match?(/Service\.new|\.call\b/),
          unauthenticated:    unauthenticated_actions.include?(action)
        }
      end
      meta
    end

    def extract_action_body(action, content)
      m = content.match(/def\s+#{Regexp.escape(action)}\b(.*?)(?=\n\s+def\s|\z)/m)
      m ? m[1] : nil
    end

    # Resolve os campos permit de uma ação.
    # Detecta três padrões:
    #   1. params.permit inline no corpo
    #   2. Um único método privado de params (ex: g_produto_params)
    #   3. Múltiplos métodos de params (ex: responsavel_params, empresa_params, contrato_params)
    #      → retorna :grouped_params com a estrutura de cada grupo
    def resolve_permit_meta(action_body, private_permit_map)
      # 1. permit inline
      raw_inline = extract_permit_fields(action_body)
      if raw_inline.is_a?(Hash)
        inline_fields = raw_inline[:scalar_fields] || []
        inline_arrays = raw_inline[:array_fields]  || []
      else
        inline_fields = raw_inline
        inline_arrays = []
      end

      if inline_fields.any? || inline_arrays.any?
        file_fields = detect_file_fields_by_name(inline_fields) | detect_file_fields_by_access(action_body)
        return { fields: inline_fields, array_fields: inline_arrays,
                 file_fields: file_fields, extra_fields: [],
                 uses_column_names: false, column_names_model: nil, grouped_params: nil }
      end

      # Detecta todos os métodos de params chamados
      called  = action_body.scan(/\b(\w+_params?\b|\w+_permit\w*)\b/).flatten.uniq
      matched = called.filter_map { |m| [m, private_permit_map[m]] if private_permit_map[m] }

      return empty_permit_meta if matched.empty?

      # Apenas um método
      if matched.size == 1
        return matched.first[1].merge(grouped_params: nil)
      end

      # Múltiplos métodos → schema agrupado
      groups = matched.map do |method_name, meta|
        group_key = method_name.sub(/_params?\z/, "").sub(/\Aparams_/, "")
        { key: group_key, meta: meta }
      end

      {
        fields:             [],
        array_fields:       [],
        file_fields:        [],
        extra_fields:       [],
        uses_column_names:  false,
        column_names_model: nil,
        grouped_params:     groups
      }
    end

    def empty_permit_meta
      { fields: [], array_fields: [], file_fields: [], extra_fields: [],
        uses_column_names: false, column_names_model: nil, grouped_params: nil }
    end

    # Extrai nomes dos campos de params.permit(...) — suporta múltiplos padrões:
    #   params.permit(:a, :b)
    #   params.require(:x).permit(:a, :b)
    #   dados.permit(:a, :b)           ← variável local que veio de params
    #   params.permit(:a, ids: [])     ← campo array
    #   params.expect(resource: [:a])
    def extract_permit_fields(text)
      fields      = []
      array_fields = []

      # Padrão 1: params[...].permit(...)  ou  params.require(...).permit(...)
      text.scan(/params(?:\[[\w:"' ]+\])?\.(?:require\([\w:"']+\)\.)?permit\((.*?)\)/m) do |args|
        parse_permit_args(args.first.to_s, fields, array_fields)
      end

      # Padrão 2: params.expect(resource: [:a, :b])
      text.scan(/params\.expect\(\s*\w+:\s*\[(.*?)\]\s*\)/m) do |args|
        parse_permit_args(args.first.to_s, fields, array_fields)
      end

      # Padrão 3: variável_local.permit(:a, :b)
      text.scan(/\b(\w+)\.permit\((.*?)\)/m) do |var, args|
        next if var == "params"
        if text.match?(/\b#{Regexp.escape(var)}\s*=.*\bparams\b/m)
          parse_permit_args(args, fields, array_fields)
        end
      end

      # Retorna estrutura rica quando há array fields, simples quando não há
      if array_fields.any?
        { scalar_fields: fields.uniq, array_fields: array_fields.uniq }
      else
        fields.uniq
      end
    end

    # Extrai campos scalares e arrays do bloco de argumentos do permit.
    # Scalar: :nome, :email, "cpf"
    # Array:  e_estudante_ids: []   →  array_fields << "e_estudante_ids"
    def parse_permit_args(raw, fields, array_fields = [])
      # Detecta padrão array: campo_name: []
      # Ex: e_estudante_ids: [], tag_ids: []
      raw.scan(/[:"']?(\w+)[:"']?\s*:\s*\[\s*\]/).flatten.each do |f|
        array_fields << f unless f.empty?
      end

      # Campos escalares: :nome, :email, "cpf"
      # Remove partes que fazem parte da sintaxe array (key: [])
      cleaned = raw.gsub(/[:"']?\w+[:"']?\s*:\s*\[\s*\]/, "")
      cleaned.scan(/[:"'](\w+)["']?/).flatten.each { |f| fields << f unless f.empty? }
    end

    # ──────────────────────────── ações customizadas ──

    def build_custom_actions(action_names, full_content, actions_meta)
      action_names.map do |name|
        ameta           = actions_meta[name] || {}
        all_file_fields = ameta[:file_fields] || []
        {
          name:               name,
          http_method:        infer_custom_http_method(name, full_content),
          on_member:          infer_on_member(name, full_content),
          extra_path_params:  extra_path_params_for(name),
          permit_fields:      ameta[:permit_fields]      || [],
          array_fields:       ameta[:array_fields]       || [],
          file_fields:        all_file_fields,
          extra_fields:       ameta[:extra_fields]       || [],
          grouped_params:     ameta[:grouped_params],
          uses_service:       ameta[:uses_service]       || false,
          is_multipart:       ameta[:is_multipart]       || all_file_fields.any?,
          uses_column_names:  ameta[:uses_column_names]  || false,
          column_names_model: ameta[:column_names_model],
          unauthenticated:    ameta[:unauthenticated]    || false
        }
      end
    end

    def infer_custom_http_method(action_name, content)
      # 1. Comentário explícito no controller
      comment = content.match(/#\s*@swagger_method_#{action_name}:\s*(\w+)/i)
      return comment[1].downcase.to_sym if comment

      # 2. Lido diretamente do routes.rb (novo formato: { method:, path_params: })
      if @routes_map.key?(action_name.to_s)
        entry = @routes_map[action_name.to_s]
        return entry.is_a?(Hash) ? entry[:method] : entry
      end

      # 3. Heurística pelo nome
      CUSTOM_HTTP_HINTS.each { |pattern, method| return method if action_name.match?(pattern) }

      # 4. Default conservador
      :post
    end

    # Retorna os path params extras declarados na rota (além do :id do member)
    def extra_path_params_for(action_name)
      entry = @routes_map[action_name.to_s]
      return [] unless entry.is_a?(Hash)
      entry[:path_params] || []
    end

    def infer_on_member(action_name, full_content)
      # Fonte primária: routes_map já parseado por parse_routes_file!
      # Se a ação está no routes_map com path_params OU foi encontrada num bloco member,
      # a informação de membro é determinada pelo contexto da rota
      routes_path = Rails.root.join("config", "routes.rb")
      return false unless File.exist?(routes_path)

      routes_content = File.read(routes_path)

      # 1. on: :collection explícito → nunca é member
      if routes_content.match?(/\b(get|post|put|patch|delete)\s+['":][^'"\n]*\b#{Regexp.escape(action_name)}\b[^'"\n]*['"]?[^\n]*on:\s*:collection/i)
        return false
      end

      # 2. Dentro de bloco collection do...end
      # Usa split em vez de regex para evitar ambiguidade com end aninhado
      if inside_block?(routes_content, "collection", action_name)
        return false
      end

      # 3. on: :member explícito
      if routes_content.match?(/\b(get|post|put|patch|delete)\s+['":][^'"\n]*\b#{Regexp.escape(action_name)}\b[^'"\n]*['"]?[^\n]*on:\s*:member/i)
        return true
      end

      # 4. Dentro de bloco member do...end
      if inside_block?(routes_content, "member", action_name)
        return true
      end

      false
    end

    # Verifica se action_name está declarado dentro de um bloco `block_type do ... end`
    # Usa rastreamento de profundidade para evitar falsos positivos com end aninhado
    def inside_block?(content, block_type, action_name)
      lines = content.lines

      lines.each_with_index do |line, idx|
        # Encontrou o início do bloco
        next unless line.match?(/\b#{block_type}\s+do\b/)

        # Coleta as linhas do bloco respeitando profundidade
        depth  = 1
        block_lines = []

        lines[(idx + 1)..].each do |inner_line|
          depth += inner_line.scan(/\bdo\b|\bbegin\b/).size
          depth -= inner_line.scan(/\bend\b/).size
          break if depth <= 0
          block_lines << inner_line
        end

        block_text = block_lines.join

        # Verifica se a action está no bloco (como símbolo, string ou action:)
        if block_text.match?(/\b(get|post|put|patch|delete)\s+:#{Regexp.escape(action_name)}\b/) ||
           block_text.match?(/\b(get|post|put|patch|delete)\s+['"][^'"]*#{Regexp.escape(action_name)}[^'"]*['"]/) ||
           block_text.match?(/action:\s*:#{Regexp.escape(action_name)}\b/)
          return true
        end
      end

      false
    end

    # Extrai ações que pulam autenticação via skip_before_action.
    # Suporta:
    #   skip_before_action :authenticate_user!, only: [:login, :refresh_token]
    #   skip_before_action :authenticate!, only: %i[login forgot_password]
    def extract_unauthenticated_actions(content)
      actions = []

      content.scan(
        /skip_before_action\s+:(?:authenticate\w*)\s*(?:,\s*only:\s*[\[%]i?\[?(.*?)\]?\s*\n)/m
      ) do |match|
        raw = match.first.to_s
        raw.scan(/[:"'](\w+)["']?/).flatten.each { |a| actions << a }
      end

      # Padrão alternativo com aspas duplas ou símbolos variados
      content.scan(/skip_before_action\s+[:'"]\w+['"]?\s*,\s*only:\s*[\[%]i?\[?([^\]]+)\]?/m) do |match|
        raw = match.first.to_s
        raw.scan(/[:"'](\w+)["']?/).flatten.each { |a| actions << a }
      end

      actions.uniq
    end

    # ──────────────────────────── detecção de arquivo ──

    def detect_multipart(body)
      MULTIPART_INDICATORS.any? { |p| body.match?(p) }
    end

    # Campos que são arquivo pelo nome (excluindo _url)
    def detect_file_fields_by_name(fields)
      fields.select { |f| file_field_by_name?(f) }
    end

    # Campos acessados via params[:x] com sinais de upload no corpo
    def detect_file_fields_by_access(body)
      fields = []

      body.scan(/params\[:(\w+)\]/).flatten.each do |f|
        fields << f if f.match?(/arquivo|file|planilha|documento|imagem|foto|anexo/)
      end

      body.scan(/params\[:(\w+)\][^\n]*(?:\.original_filename|\.read|\.content_type)/).flatten.each do |f|
        fields << f
      end

      fields.uniq
    end

    def file_field_by_name?(name)
      n = name.to_s
      return false if n.end_with?("_url") || n.end_with?("url")
      return false if n == "descricao_anexo"
      n.match?(FILE_FIELD_PATTERN)
    end

    # ──────────────────── leitura do routes.rb ──

    # Lê config/routes.rb e extrai:
    #   { "action_name" => { method: :patch, path_params: ["g_empresa_id"], on_member: true } }
    #
    # Suporta os padrões:
    #   get    :jti_info
    #   patch  'vincular_empresa/:g_empresa_id', action: :vincular_empresa
    #   post   "login", to: "auth#login"
    def parse_routes_file!
      routes_path = Rails.root.join("config", "routes.rb")
      return {} unless File.exist?(routes_path)

      content    = File.read(routes_path)
      routes_map = {}

      # Padrão 1: get/post/etc :action_name  (símbolo simples)
      content.scan(/\b(get|post|put|patch|delete)\s+:(\w+)/) do |method, action|
        next if CRUD_ACTIONS.include?(action)
        routes_map[action] ||= { method: method.downcase.to_sym, path_params: [] }
      end

      # Padrão 2: patch 'path/:param', action: :action_name
      # Ex: patch 'vincular_empresa/:g_empresa_id', action: :vincular_empresa
      content.scan(
        /\b(get|post|put|patch|delete)\s+['"]([^'"]+)['"]\s*,\s*action:\s*:(\w+)/
      ) do |method, path, action|
        next if CRUD_ACTIONS.include?(action)
        path_params = path.scan(/:(\w+)/).flatten  # extrai :g_empresa_id → "g_empresa_id"
        routes_map[action] ||= { method: method.downcase.to_sym, path_params: path_params }
      end

      # Padrão 3: get "path", to: "controller#action"
      content.scan(
        /\b(get|post|put|patch|delete)\s+['"]([^'"]+)['"]\s*,\s*to:\s*['"][^'"#]*#(\w+)['"]/
      ) do |method, path, action|
        next if CRUD_ACTIONS.include?(action)
        path_params = path.scan(/:(\w+)/).flatten
        routes_map[action] ||= { method: method.downcase.to_sym, path_params: path_params }
      end

      # Padrão 4: get "path/only"  (sem action explícita — infere pelo path)
      content.scan(/\b(get|post|put|patch|delete)\s+['"]([^'"]+)['"]\s*(?!,)/) do |method, path|
        action = path.split("/").last.to_s.gsub(/:.*/, "").gsub(/[^a-z_]/, "")
        next if action.empty? || CRUD_ACTIONS.include?(action)
        path_params = path.scan(/:(\w+)/).flatten
        routes_map[action] ||= { method: method.downcase.to_sym, path_params: path_params }
      end

      routes_map
    end

    # ──────────────────────────────────── helpers ──

    def extract_version(klass)
      m = klass.match(/::V(\d+)::/)
      m ? "v#{m[1]}" : "v1"
    end

    def infer_model_name(resource_name)
      singular = resource_name.singularize rescue resource_name.sub(/s$/, "")
      parts    = singular.split("_")
      parts.first == "g" ? "G" + parts[1..].map(&:capitalize).join : parts.map(&:capitalize).join
    end

    def crud_http_method(action)
      { "index" => :get, "show" => :get, "create" => :post,
        "update" => :patch, "destroy" => :delete }.fetch(action, :get)
    end

    def extract_swagger_meta(content)
      meta  = {}
      tag_m = content.match(/#\s*@swagger_tag:\s*(.+)/)
      meta[:tag] = tag_m[1].strip if tag_m

      content.scan(/#\s*@swagger_summary_(\w+):\s*(.+)/).each    { |a, v| meta[:"summary_#{a}"]     = v.strip }
      content.scan(/#\s*@swagger_description_(\w+):\s*(.+)/).each { |a, v| meta[:"description_#{a}"] = v.strip }

      # @swagger_params_login: email, password
      # Permite documentar campos do body de ações sem params.permit (ex: AuthController)
      content.scan(/#\s*@swagger_params_(\w+):\s*(.+)/).each do |action, fields_str|
        meta[:"params_#{action}"] = fields_str.strip.split(/\s*,\s*/).map(&:strip)
      end

      # @swagger_response_login: access_token, refresh_token, user
      # Documenta campos da resposta
      content.scan(/#\s*@swagger_response_(\w+):\s*(.+)/).each do |action, fields_str|
        meta[:"response_#{action}"] = fields_str.strip.split(/\s*,\s*/).map(&:strip)
      end

      meta
    end
  end
end

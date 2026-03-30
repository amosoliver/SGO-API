# frozen_string_literal: true
# lib/swagger/openapi_builder.rb
#
# Monta o documento OpenAPI 3.0 completo a partir do SchemaParser + ControllerParser.
#
# Lógica de schemas de input por ação:
#   1. Se a ação usa Model.column_names  → pega campos do schema.rb + extras como binary
#   2. Se tem params.permit com campos   → gera schema dinâmico com belongs-to expandido
#   3. Se não tem permit detectado       → usa o ModelInput padrão gerado pelo schema.rb
#
# Belongs-to:
#   Campos _id → mantém FK integer
#                + adiciona objeto aninhado opcional com campos da tabela relacionada
#                  (apenas tabelas "ricas" — lookup/enum tables são ignoradas)
#
# Multipart:
#   Se qualquer campo for arquivo ou a ação usar uploads → content-type multipart/form-data

module Swagger
  class OpenapiBuilder
    ID_PARAM = {
      name: "id", in: "path", required: true,
      schema: { type: "integer", format: "int64" },
      description: "ID do registro"
    }.freeze

    PAGINATION_PARAMS = [
      { name: "page",     in: "query", required: false,
        schema: { type: "integer", default: 1 },  description: "Número da página" },
      { name: "per_page", in: "query", required: false,
        schema: { type: "integer", default: 25 }, description: "Itens por página" }
    ].freeze

    RANSACK_PARAM = {
      name: "q", in: "query", required: false,
      style: "deepObject", explode: true,
      schema: {
        type: "object",
        additionalProperties: { type: "string" },
        example: {
          "nome_cont"        => "joao",
          "email_i_cont"     => "JOAO",
          "cpf_eq"           => "12345678900",
          "created_at_gteq"  => "2024-01-01",
          "created_at_lteq"  => "2024-12-31",
          "ativo_eq"         => "true",
          "s"                => "nome asc"
        }
      },
      description: <<~DESC.strip
        Filtros Ransack. Use `campo_predicado=valor`.

        **Predicados mais usados:**
        | Predicado | Significado | Case sensitive? |
        |-----------|-------------|-----------------|
        | `_cont` | contém (LIKE) | ✅ Sim |
        | `_i_cont` | contém (ILIKE) | ❌ Não |
        | `_eq` | igual | — |
        | `_not_eq` | diferente | — |
        | `_start` | começa com | ✅ Sim |
        | `_i_start` | começa com | ❌ Não |
        | `_end` | termina com | ✅ Sim |
        | `_gteq` | maior ou igual (>=) | — |
        | `_lteq` | menor ou igual (<=) | — |
        | `_null` | nulo | — |
        | `_present` | não nulo | — |

        **Ordenação:** `q[s]=campo+asc` ou `q[s]=campo+desc`

        **Exemplos:**
        - `q[nome_i_cont]=joao` → busca "João", "JOAO", "joao" (recomendado)
        - `q[email_eq]=user@example.com` → exato
        - `q[s]=created_at+desc` → ordenar por data decrescente
      DESC
    }.freeze

    # Tabelas que são apenas lookups/enums — não expandir como objeto aninhado
    LOOKUP_TABLE_PATTERN = /\A(g_tipos_|g_status\z|g_sexos\z|g_regioes\z|
                               g_paises\z|g_periodos_|g_graus_|g_estados_civis\z)/x.freeze

    def initialize(schema_parser, controller_parser, config = {})
      @schema_parser     = schema_parser
      @controller_parser = controller_parser
      @config            = config
      @dynamic_schemas   = {}
    end

    def build
      paths      = build_paths       # popula @dynamic_schemas como efeito colateral
      components = build_components  # usa @dynamic_schemas já preenchidos

      {
        openapi:    "3.0.3",
        info:       build_info,
        servers:    [{ url: @config.fetch(:server_url, "/"), description: "Servidor da API" }],
        tags:       build_tags,
        paths:      paths,
        components: components,
        security:   [{ BearerAuth: [] }]
      }
    end

    private

    # ──────────────────────────────────────── info / tags ──

    def build_info
      {
        title:       @config.fetch(:title,       "API"),
        version:     @config.fetch(:version,     "1.0.0"),
        description: @config.fetch(:description, "Documentação OpenAPI gerada automaticamente")
      }
    end

    def build_tags
      @controller_parser.to_resources.map do |r|
        tag = r[:extra_meta][:tag] || r[:model]
        { name: tag, description: "Gerenciamento de #{r[:model]}" }
      end.uniq { |t| t[:name] }
    end

    # ──────────────────────────────────────────── paths ──

    def build_paths
      paths = {}

      @controller_parser.to_resources.each do |r|
        base  = "/api/#{r[:version]}/#{r[:resource]}"
        model = r[:model]
        tag   = r[:extra_meta][:tag] || model
        meta  = r[:extra_meta]
        ameta = r[:actions_meta] || {}

        # Coleção: GET /resource  POST /resource
        col = {}
        col[:get]  = index_op(model, tag, meta, ameta["index"])   if r[:actions].include?("index")
        col[:post] = create_op(model, tag, meta, ameta["create"])  if r[:actions].include?("create")
        paths[base] = col unless col.empty?

        # Membro: GET /resource/{id}  PATCH  PUT  DELETE
        mem = {}
        mem[:get]    = show_op(model, tag, meta, ameta["show"])                        if r[:actions].include?("show")
        mem[:patch]  = update_op(model, tag, meta, ameta["update"])                    if r[:actions].include?("update")
        mem[:put]    = update_op(model, tag, meta, ameta["update"], "put")             if r[:actions].include?("update")
        mem[:delete] = destroy_op(model, tag, meta, ameta["destroy"])                  if r[:actions].include?("destroy")
        paths["#{base}/{id}"] = mem unless mem.empty?

        # Ações customizadas
        Array(r[:custom_actions]).each do |ca|
          # Base: member tem {id}, collection não tem
          base_route = ca[:on_member] ? "#{base}/{id}" : base

          # Acrescenta params extras da rota: vincular_empresa/:g_empresa_id → /{g_empresa_id}
          extra_segments = Array(ca[:extra_path_params]).map { |p| "{#{p}}" }.join("/")
          route = if extra_segments.empty?
                    "#{base_route}/#{ca[:name]}"
                  else
                    "#{base_route}/#{ca[:name]}/#{extra_segments}"
                  end

          paths[route] ||= {}
          paths[route][ca[:http_method]] = custom_op(ca, model, tag, meta)
        end
      end

      paths
    end

    # ───────────────────────────────────────── operações CRUD ──

    def index_op(model, tag, meta, action_meta = nil)
      plural = model.pluralize rescue "#{model}s"
      op = {
        tags:        [tag],
        summary:     meta[:summary_index] || "Listar #{plural}",
        operationId: "list#{model}",
        parameters:  [RANSACK_PARAM, *PAGINATION_PARAMS],
        responses: {
          "200" => json_response("Lista paginada de #{plural}", "#{model}List"),
          "401" => ref_response("Unauthorized")
        }
      }
      op[:security] = [] if action_meta&.dig(:unauthenticated)
      op
    end

    def show_op(model, tag, meta, action_meta = nil)
      op = {
        tags:        [tag],
        summary:     meta[:summary_show] || "Buscar #{model} por ID",
        operationId: "get#{model}",
        parameters:  [ID_PARAM],
        responses: {
          "200" => json_response("#{model} encontrado", model),
          "401" => ref_response("Unauthorized"),
          "404" => ref_response("NotFound")
        }
      }
      op[:security] = [] if action_meta&.dig(:unauthenticated)
      op
    end

    def create_op(model, tag, meta, action_meta = nil)
      schema_ref = resolve_input_schema(model, "create", action_meta)
      content    = build_request_content(schema_ref, action_meta)
      op = {
        tags:        [tag],
        summary:     meta[:summary_create] || "Criar #{model}",
        operationId: "create#{model}",
        requestBody: { required: true, content: content },
        responses: {
          "201" => json_response("#{model} criado com sucesso", model),
          "401" => ref_response("Unauthorized"),
          "422" => ref_response("UnprocessableEntity")
        }
      }
      op[:description] = meta[:description_create] if meta[:description_create]
      op
    end

    def update_op(model, tag, meta, action_meta = nil, method = "patch")
      schema_ref = resolve_input_schema(model, "update", action_meta)
      content    = build_request_content(schema_ref, action_meta)
      {
        tags:        [tag],
        summary:     meta[:summary_update] || "Atualizar #{model}",
        operationId: method == "put" ? "replace#{model}" : "update#{model}",
        parameters:  [ID_PARAM],
        requestBody: { required: true, content: content },
        responses: {
          "200" => json_response("#{model} atualizado", model),
          "401" => ref_response("Unauthorized"),
          "404" => ref_response("NotFound"),
          "422" => ref_response("UnprocessableEntity")
        }
      }
    end

    def destroy_op(model, tag, meta, action_meta = nil)
      op = {
        tags:        [tag],
        summary:     meta[:summary_destroy] || "Remover #{model}",
        operationId: "delete#{model}",
        parameters:  [ID_PARAM],
        responses: {
          "204" => { description: "#{model} removido com sucesso" },
          "401" => ref_response("Unauthorized"),
          "404" => ref_response("NotFound")
        }
      }
      op[:security] = [] if action_meta&.dig(:unauthenticated)
      op
    end

    # ──────────────────────────────── operação customizada ──

    def custom_op(ca, model, tag, meta)
      action      = ca[:name]
      http_method = ca[:http_method]
      on_member   = ca[:on_member]

      op = {
        tags:        [tag],
        summary:     meta[:"summary_#{action}"] || action.tr("_", " ").capitalize,
        operationId: "#{action}#{model}"
      }
      op[:description] = meta[:"description_#{action}"] if meta[:"description_#{action}"]
      op[:security]    = [] if ca[:unauthenticated]

      # ── Path parameters ──
      path_params = []
      path_params << ID_PARAM if on_member

      # Extra path params da rota — filtra redundâncias com o {id} do member
      # Ex: listar_veiculos/:t_contrato_id em member → t_contrato_id é o mesmo que {id}, ignorar
      Array(ca[:extra_path_params]).each do |param_name|
        # Ignora se o param claramente referencia o próprio recurso (mesmo modelo)
        next if redundant_path_param?(param_name, model)

        path_params << {
          name:        param_name,
          in:          "path",
          required:    true,
          schema:      ControllerParser.infer_field_type(param_name),
          description: param_name.tr("_", " ").capitalize
        }
      end

      # ── Query parameters ──
      query_params = []
      if http_method == :get
        if list_action?(action)
          # Listagem — sempre adiciona ransack + paginação (member ou collection)
          query_params = [RANSACK_PARAM, *PAGINATION_PARAMS]
        elsif !on_member
          # GET collection simples → paginação básica
          query_params = PAGINATION_PARAMS.dup
        end
        # GET member sem listagem → sem query params automáticos
      end

      all_params = path_params + query_params
      op[:parameters] = all_params unless all_params.empty?

      # ── Request body (só para POST/PUT/PATCH) ──
      unless %i[get delete].include?(http_method)
        schema_ref = resolve_input_schema(model, action, ca)
        content    = build_request_content(schema_ref, ca)
        op[:requestBody] = { required: true, content: content }
      end

      op[:responses] = {
        "200" => json_response("Operação concluída com sucesso", model),
        "400" => ref_response("BadRequest"),
        "401" => ref_response("Unauthorized"),
        "404" => ref_response("NotFound"),
        "422" => ref_response("UnprocessableEntity")
      }
      op
    end

    # Heurística: a ação parece ser uma listagem paginada?
    def list_action?(action_name)
      action_name.to_s.match?(
        /\A(listar|list|buscar|search|filtrar|filter|index|all|todos|todas)|
         _por_\w+\z|
         _(list|all|veiculos|estudantes|contratos|usuarios|documentos|rotas)\z/ix
      )
    end

    # Um path param é redundante se referencia o mesmo recurso que já está em {id}
    # Ex: listar_veiculos/:t_contrato_id em TContratosController → t_contrato_id == id
    def redundant_path_param?(param_name, model)
      # Converte model para snake_case e compara com o param sem _id
      model_snake = model
                      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                      .downcase  # TContrato → t_contrato

      param_base = param_name.to_s.sub(/_id\z/, "")  # t_contrato_id → t_contrato
      param_base == model_snake
    end

    # ─────────────────────── resolve content-type do requestBody ──

    # Retorna o hash "content" do requestBody com o content-type correto
    def build_request_content(schema_ref, action_meta)
      is_multipart = action_meta&.dig(:is_multipart) ||
                     action_meta&.dig(:file_fields)&.any?

      if schema_ref.is_a?(Hash) && schema_ref[:_multipart]
        ref = { "$ref" => schema_ref[:_ref] }
        { "multipart/form-data" => { schema: ref } }
      elsif is_multipart
        { "multipart/form-data" => { schema: schema_ref } }
      else
        { "application/json" => { schema: schema_ref } }
      end
    end

    # ────────────────────── resolve schema de input por ação ──

    def resolve_input_schema(model, action, action_meta)
      unless action_meta
        fallback = schema_exists?("#{model}Input") ? "#{model}Input" : "GenericInput"
        return { "$ref" => "#/components/schemas/#{fallback}" }
      end

      # Padrão com múltiplos grupos de params
      if action_meta[:grouped_params]&.any?
        schema_name = "#{model}#{camelize(action)}Input"
        @dynamic_schemas[schema_name] ||= build_grouped_schema(action_meta[:grouped_params])
        return { "$ref" => "#/components/schemas/#{schema_name}" }
      end

      # Remove campos que já são path params da URL
      path_param_names = Array(action_meta[:extra_path_params]).map(&:to_s)
      path_param_names << "id" if action_meta[:on_member]

      fields       = (action_meta[:permit_fields] || []).reject { |f| path_param_names.include?(f.to_s) }
      array_fields = (action_meta[:array_fields]  || []).reject { |f| path_param_names.include?(f.to_s) }
      file_fields  = (action_meta[:file_fields]   || []).reject { |f| path_param_names.include?(f.to_s) }
      extra_fields = (action_meta[:extra_fields]  || []).reject { |f| path_param_names.include?(f.to_s) }

      is_multipart      = action_meta[:is_multipart] || file_fields.any?
      uses_column_names = action_meta[:uses_column_names] || false
      col_model         = action_meta[:column_names_model]

      has_content = fields.any? || file_fields.any? || uses_column_names || array_fields.any?

      unless has_content
        fallback = schema_exists?("#{model}Input") ? "#{model}Input" : "GenericInput"
        return { "$ref" => "#/components/schemas/#{fallback}" }
      end

      schema_name = "#{model}#{camelize(action)}Input"

      @dynamic_schemas[schema_name] ||= if uses_column_names
                                          build_column_names_schema(col_model || model, file_fields, extra_fields)
                                        else
                                          build_fields_schema(fields, file_fields: file_fields, array_fields: array_fields)
                                        end

      ref = "#/components/schemas/#{schema_name}"
      is_multipart ? { _multipart: true, _ref: ref } : { "$ref" => ref }
    end

    # Monta schema com objetos aninhados por grupo de params.
    # Ex: responsavel_params + empresa_params + contrato_params gera:
    # {
    #   responsavel: { type: object, properties: { nome:, cpf:, email:, ... } },
    #   empresa:     { type: object, properties: { razao_social:, cpf_cnpj:, ... } },
    #   contrato:    { type: object, properties: { descricao:, data_inicio:, ... } }
    # }
    def build_grouped_schema(groups)
      properties = {}

      groups.each do |group|
        key    = group[:key]
        meta   = group[:meta]
        fields = meta[:fields] || []
        next if fields.empty?

        group_props = {}
        fields.each do |field|
          group_props[field] = ControllerParser.infer_field_type(field)
                                               .merge(description: field.tr("_", " ").capitalize)
        end

        properties[key] = {
          type:        "object",
          description: "Dados de #{key.tr("_", " ")}",
          properties:  group_props
        }
      end

      {
        type: "object",
        description: "Corpo agrupado por contexto — cada chave corresponde a um grupo de parâmetros",
        properties:  properties
      }
    end

    # ─────── schema a partir de Model.column_names + campos extras ──

    # Pega todas as colunas writable do schema.rb + adiciona extras (ex: :imagem_produto)
    def build_column_names_schema(model_name, file_fields, extra_fields)
      ignored = %w[id created_at updated_at created_by updated_by deleted_at
                   encrypted_password reset_password_token reset_password_sent_at
                   remember_created_at refresh_token token_primeiro_acesso]

      table_name = find_table_for_model(model_name)
      properties = {}

      if table_name && @schema_parser.tables[table_name]
        @schema_parser.tables[table_name]
                      .reject { |c| ignored.include?(c[:name]) }
                      .each do |col|
          type_def = SchemaParser::COLUMN_TYPE_MAP[col[:type]] || { type: "string" }
          properties[col[:name]] = type_def.dup.merge(
            description: col[:name].tr("_", " ").capitalize
          )
        end
      end

      # Campos extras declarados no permit além do *permitted
      extra_fields.each do |field|
        next if properties.key?(field)
        if file_field_by_name?(field) || file_fields.include?(field)
          properties[field] = { type: "string", format: "binary",
                                description: field.tr("_", " ").capitalize }
        else
          properties[field] = ControllerParser.infer_field_type(field)
                                              .merge(description: field.tr("_", " ").capitalize)
        end
      end

      # Garante campos de arquivo como binary
      file_fields.each do |ff|
        properties[ff] = { type: "string", format: "binary",
                           description: ff.tr("_", " ").capitalize }
      end

      {
        type: "object",
        description: "Enviado como multipart/form-data: campos de texto como form-fields, arquivos como binary",
        properties: properties
      }
    end

    # ────────────────── schema a partir de lista de campos do permit ──

    # Monta propriedades direto do permit — sem expansão automática de belongs-to.
    # Suporta:
    #   scalar fields → tipo simples (string, integer, boolean, etc.)
    #   array_fields  → { type: array, items: { type: integer/string } }
    #   file_fields   → { type: string, format: binary }
    def build_fields_schema(fields, file_fields: [], array_fields: [])
      properties = {}

      # Campos escalares
      fields.each do |field|
        if file_fields.include?(field) || file_field_by_name?(field)
          properties[field] = { type: "string", format: "binary",
                                description: field.tr("_", " ").capitalize }
        else
          properties[field] = ControllerParser.infer_field_type(field)
                                              .merge(description: field.tr("_", " ").capitalize)
        end
      end

      # Campos array: e_estudante_ids: [] → array of integers
      Array(array_fields).each do |field|
        item_type = field.to_s.end_with?("_ids") ? { type: "integer", format: "int64" } : { type: "string" }
        properties[field] = {
          type:        "array",
          description: field.tr("_", " ").capitalize,
          items:       item_type
        }
      end

      # Campos de arquivo que não estavam no permit explícito
      file_fields.each do |ff|
        next if properties.key?(ff)
        properties[ff] = { type: "string", format: "binary",
                           description: ff.tr("_", " ").capitalize }
      end

      { type: "object", properties: properties }
    end

    # ─────────── objeto aninhado para belongs-to (apenas tabelas ricas) ──

    def nested_object_for_fk(fk_field, all_tables)
      base       = fk_field.sub(/_id\z/, "")
      table_name = ["#{base}s", "#{base}es", base].find { |c| all_tables.key?(c) }
      return nil unless table_name
      return nil if table_name.match?(LOOKUP_TABLE_PATTERN)

      ignored = %w[id created_at updated_at created_by updated_by deleted_at]
      cols    = all_tables[table_name].reject { |c| ignored.include?(c[:name]) }
      return nil if cols.size <= 1                          # só descricao → lookup
      return nil if cols.map { |c| c[:name] } == ["descricao"]

      nested_props = {}
      cols.each do |col|
        next if col[:name].end_with?("_id")                 # evita recursão
        type_def = SchemaParser::COLUMN_TYPE_MAP[col[:type]] || { type: "string" }
        nested_props[col[:name]] = type_def.dup.merge(
          description: col[:name].tr("_", " ").capitalize
        )
      end
      return nil if nested_props.empty?

      {
        key:    base,
        schema: {
          type:        "object",
          description: "Dados de #{base.tr("_", " ")} — alternativa ao #{fk_field}",
          properties:  nested_props
        }
      }
    end

    # ──────────────────────────────────── components ──

    def build_components
      {
        securitySchemes: {
          BearerAuth: {
            type: "http", scheme: "bearer", bearerFormat: "JWT",
            description: "Token JWT obtido em /api/v1/auth/login"
          }
        },
        schemas: @schema_parser.to_openapi_schemas
                               .merge(@dynamic_schemas)
                               .merge(shared_schemas),
        responses: {
          "Unauthorized"        => error_response("Autenticação necessária"),
          "NotFound"            => error_response("Registro não encontrado"),
          "BadRequest"          => error_response("Requisição inválida"),
          "UnprocessableEntity" => {
            description: "Erros de validação",
            content: { "application/json" => {
              schema: { "$ref" => "#/components/schemas/ValidationError" }
            } }
          }
        }
      }
    end

    # ──────────────────────────────────── helpers ──

    # Verifica se um schema existirá no documento final.
    # Checa: tabelas do schema.rb (modelo e input), schemas dinâmicos já gerados,
    # e schemas compartilhados fixos.
    def schema_exists?(schema_name)
      # Schemas compartilhados sempre existem
      return true if %w[Error ValidationError GenericResponse GenericInput].include?(schema_name)

      # Schemas dinâmicos já gerados até agora
      return true if @dynamic_schemas.key?(schema_name)

      # Modelo derivado de tabela do schema.rb (ex: "GCliente", "GClienteInput", "GClienteList")
      @schema_parser.tables.any? do |table_name, _|
        model = @schema_parser.model_name_for_table(table_name)
        schema_name == model ||
          schema_name == "#{model}Input" ||
          schema_name == "#{model}List"
      end
    end

    # Retorna $ref se o schema existir, senão retorna schema genérico inline
    def safe_schema_ref(schema_name)
      if schema_exists?(schema_name)
        { "$ref" => "#/components/schemas/#{schema_name}" }
      else
        { "$ref" => "#/components/schemas/GenericResponse" }
      end
    end

    def json_response(description, schema_name)
      { description: description,
        content: { "application/json" => {
          schema: safe_schema_ref(schema_name)
        } } }
    end

    def ref_response(name)
      { "$ref" => "#/components/responses/#{name}" }
    end

    def error_response(description)
      { description: description,
        content: { "application/json" => {
          schema: { "$ref" => "#/components/schemas/Error" }
        } } }
    end

    def shared_schemas
      {
        "Error" => {
          type: "object",
          properties: { error: { type: "string" } }
        },
        "ValidationError" => {
          type: "object",
          properties: {
            errors: {
              type: "object",
              additionalProperties: { type: "array", items: { type: "string" } }
            }
          }
        },
        # Usado como resposta quando o model não tem tabela no schema.rb
        # (ex: AuthController, endpoints de serviço, etc.)
        "GenericResponse" => {
          type: "object",
          description: "Resposta do endpoint",
          additionalProperties: true
        },
        # Usado como input quando não há params.permit detectado
        # e o model não tem tabela correspondente no schema.rb
        "GenericInput" => {
          type: "object",
          description: "Parâmetros do endpoint",
          additionalProperties: true
        }
      }
    end

    def camelize(str)
      str.to_s.split("_").map(&:capitalize).join
    end

    # "GProduto" → "g_produtos"
    def find_table_for_model(model_name)
      underscored = model_name.to_s
                              .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                              .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                              .downcase
      ["#{underscored}s", "#{underscored}es", underscored]
        .find { |c| @schema_parser.tables.key?(c) }
    end

    def file_field_by_name?(name)
      n = name.to_s
      return false if n.end_with?("_url") || n.end_with?("url")
      return false if n == "descricao_anexo"
      n.match?(ControllerParser::FILE_FIELD_PATTERN)
    end
  end
end

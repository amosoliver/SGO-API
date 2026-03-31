# frozen_string_literal: true

module SeedHelpers
  module_function

  def upsert_record(model, finder_attrs, attrs = {})
    record = model.find_or_initialize_by(finder_attrs)
    record.assign_attributes(attrs)
    record.deleted_at = nil if record.respond_to?(:deleted_at=)
    record.save!
    record
  end

  def create_user!(email:, cpf:, nome:, password:, perfil:, igreja:, tipo_pessoa:, ativo: true)
    pessoa = upsert_record(
      GPessoa,
      { cpf: cpf },
      {
        descricao: nome,
        email: email,
        ativo: ativo,
        g_igreja: igreja,
        g_tipo_pessoa: tipo_pessoa
      }
    )

    usuario = GUsuario.find_or_initialize_by(email: email)
    usuario.g_pessoa = pessoa
    usuario.password = password
    usuario.password_confirmation = password
    usuario.ativo = ativo
    usuario.primeiro_acesso = false
    usuario.deleted_at = nil
    usuario.save!

    GUsuarioPerfil.active.where(g_usuario_id: usuario.id).where.not(g_perfil_id: perfil.id).update_all(deleted_at: Time.current, updated_at: Time.current)
    vinculo = GUsuarioPerfil.unscoped.find_or_initialize_by(g_usuario_id: usuario.id, g_perfil_id: perfil.id)
    vinculo.deleted_at = nil
    vinculo.save!

    usuario
  end

  def assign_naipe!(pessoa:, instrumento:, naipe:, posicao:, principal:)
    vinculo = GPessoaNaipe.find_or_initialize_by(
      g_pessoa_id: pessoa.id,
      g_instrumento_id: instrumento.id,
      g_naipe_id: naipe.id
    )
    vinculo.posicao = posicao
    vinculo.principal = principal
    vinculo.save!
    vinculo
  end
end

include SeedHelpers

puts "Sincronizando permissoes e perfis..."
PermissionSyncService.new.call
ProfilePermissionSyncService.new.call

perfis = GPerfil.active.where(descricao: %w[ADM MAESTRO CORISTA]).index_by(&:descricao)

puts "Criando geografia e estruturas base..."
brasil = upsert_record(GPais, { sigla: "BR" }, { descricao: "Brasil" })
rondonia = upsert_record(GEstado, { sigla: "RO", g_pais_id: brasil.id }, { descricao: "Rondonia" })
amazonas = upsert_record(GEstado, { sigla: "AM", g_pais_id: brasil.id }, { descricao: "Amazonas" })

porto_velho = upsert_record(GCidade, { descricao: "Porto Velho", g_estado_id: rondonia.id })
ji_parana = upsert_record(GCidade, { descricao: "Ji-Parana", g_estado_id: rondonia.id })
manaus = upsert_record(GCidade, { descricao: "Manaus", g_estado_id: amazonas.id })

igrejas = [
  upsert_record(GIgreja, { descricao: "Igreja Central de Porto Velho" }, { endereco: "Av. Sete de Setembro, 1000", ativo: true, g_cidade: porto_velho }),
  upsert_record(GIgreja, { descricao: "Igreja Esperanca de Ji-Parana" }, { endereco: "Rua das Flores, 250", ativo: true, g_cidade: ji_parana }),
  upsert_record(GIgreja, { descricao: "Igreja da Graca de Manaus" }, { endereco: "Av. Djalma Batista, 500", ativo: true, g_cidade: manaus })
]

tipos_pessoa = %w[Corista Maestro Musico Visitante Regente].map do |descricao|
  upsert_record(GTipoPessoa, { descricao: descricao })
end.index_by(&:descricao)

puts "Criando instrumentos e naipes..."
instrumentos_config = {
  "Soprano" => ["Primeiro Soprano", "Segundo Soprano"],
  "Contralto" => ["Primeiro Contralto", "Segundo Contralto"],
  "Tenor" => ["Primeiro Tenor", "Segundo Tenor"],
  "Baixo" => ["Primeiro Baixo", "Segundo Baixo"],
  "Violino" => ["Violino I", "Violino II"],
  "Viola" => ["Viola"],
  "Violoncelo" => ["Violoncelo"],
  "Flauta" => ["Flauta"],
  "Clarinete" => ["Clarinete"],
  "Piano" => ["Piano"]
}

instrumentos = {}
naipes = {}

instrumentos_config.each_with_index do |(instrumento_nome, naipes_nomes), index|
  instrumento = upsert_record(GInstrumento, { descricao: instrumento_nome }, { ordem: index + 1 })
  instrumentos[instrumento_nome] = instrumento

  naipes_nomes.each_with_index do |naipe_nome, naipe_index|
    naipe = upsert_record(GNaipe, { descricao: naipe_nome })
    naipes[naipe_nome] = naipe

    upsert_record(
      GInstrumentoNaipe,
      { g_instrumento_id: instrumento.id, g_naipe_id: naipe.id },
      { ordem: naipe_index + 1 }
    )
  end
end

puts "Criando corais, orquestras e repertorio..."
corais = igrejas.map do |igreja|
  upsert_record(CCoral, { descricao: "Coral #{igreja.descricao}" }, { ativo: true, g_igreja: igreja })
end

orquestras = igrejas.map do |igreja|
  upsert_record(OOrquestra, { descricao: "Orquestra #{igreja.descricao}" }, { ativo: true, g_igreja: igreja })
end

musicas = [
  { descricao: "Grandioso Es Tu", tonalidade: "G", bpm: 72, duracao: "04:00" },
  { descricao: "Porque Ele Vive", tonalidade: "A", bpm: 76, duracao: "03:45" },
  { descricao: "Rude Cruz", tonalidade: "D", bpm: 68, duracao: "04:20" },
  { descricao: "Tu Es Fiel Senhor", tonalidade: "C", bpm: 70, duracao: "03:50" },
  { descricao: "Santo Espirito", tonalidade: "E", bpm: 74, duracao: "04:10" },
  { descricao: "A Ele a Gloria", tonalidade: "F", bpm: 80, duracao: "03:30" }
].map do |attrs|
  upsert_record(MMusica, { descricao: attrs[:descricao] }, attrs)
end

musicas.each do |musica|
  instrumentos.values.first(6).each do |instrumento|
    relacao = GInstrumentoNaipe.active.where(g_instrumento_id: instrumento.id).order(:ordem, :id).first
    naipe = relacao&.g_naipe
    next if naipe.blank?

    upsert_record(
      MMaterial,
      { descricao: "#{musica.descricao} - #{instrumento.descricao}", m_musica_id: musica.id, g_instrumento_naipe_id: relacao.id },
      {
        tipo: "partitura",
        arquivo_url: "https://example.com/materials/#{musica.descricao.parameterize}-#{instrumento.descricao.parameterize}.pdf"
      }
    )
  end
end

puts "Criando usuarios fake..."
admin_email = ENV.fetch("ADMIN_EMAIL", "admin@sgo.local")
admin_password = ENV.fetch("ADMIN_PASSWORD", "Admin@123")
admin_cpf = ENV.fetch("ADMIN_CPF", "12345678901")

admin = create_user!(
  email: admin_email,
  cpf: admin_cpf,
  nome: ENV.fetch("ADMIN_NOME", "Administrador"),
  password: admin_password,
  perfil: perfis.fetch("ADM"),
  igreja: igrejas.first,
  tipo_pessoa: tipos_pessoa.fetch("Regente")
)

maestro = create_user!(
  email: "maestro@sgo.local",
  cpf: "12345678902",
  nome: "Maestro Elias Souza",
  password: "102030",
  perfil: perfis.fetch("MAESTRO"),
  igreja: igrejas.first,
  tipo_pessoa: tipos_pessoa.fetch("Maestro")
)

coristas_config = [
  ["ana.silva@sgo.local", "12345678903", "Ana Silva", "Soprano", "Primeiro Soprano"],
  ["bruno.lima@sgo.local", "12345678904", "Bruno Lima", "Tenor", "Primeiro Tenor"],
  ["carla.rocha@sgo.local", "12345678905", "Carla Rocha", "Contralto", "Segundo Contralto"],
  ["diego.costa@sgo.local", "12345678906", "Diego Costa", "Baixo", "Primeiro Baixo"],
  ["ester.almeida@sgo.local", "12345678907", "Ester Almeida", "Violino", "Violino I"],
  ["fabio.melo@sgo.local", "12345678908", "Fabio Melo", "Flauta", "Flauta"]
]

coristas = coristas_config.each_with_index.map do |(email, cpf, nome, instrumento_nome, naipe_nome), index|
  usuario = create_user!(
    email: email,
    cpf: cpf,
    nome: nome,
    password: "102030",
    perfil: perfis.fetch("CORISTA"),
    igreja: igrejas[index % igrejas.size],
    tipo_pessoa: tipos_pessoa.fetch("Corista")
  )

  assign_naipe!(
    pessoa: usuario.g_pessoa,
    instrumento: instrumentos.fetch(instrumento_nome),
    naipe: naipes.fetch(naipe_nome),
    posicao: index.even? ? "Titular" : "Apoio",
    principal: index.even?
  )

  usuario
end

puts "Criando pessoas sem login..."
[
  ["Visitante Maria", "12345678911", "visitante.maria@sgo.local", igrejas.first, tipos_pessoa.fetch("Visitante")],
  ["Musico Daniel", "12345678912", "musico.daniel@sgo.local", igrejas.last, tipos_pessoa.fetch("Musico")]
].each do |nome, cpf, email, igreja, tipo|
  upsert_record(
    GPessoa,
    { cpf: cpf },
    {
      descricao: nome,
      email: email,
      ativo: true,
      g_igreja: igreja,
      g_tipo_pessoa: tipo
    }
  )
end

puts "Criando eventos e programacoes..."
seed_today = Time.zone.today
eventos_config = [
  ["Ensaio Geral de Domingo", seed_today.advance(days: 7).to_time.change(hour: 18), igrejas.first, corais.first, orquestras.first],
  ["Culto Especial de Louvor", seed_today.advance(days: 14).to_time.change(hour: 19), igrejas.second, corais.second, orquestras.second],
  ["Cantata de Pascoa", seed_today.advance(days: 21).to_time.change(hour: 20), igrejas.third, corais.third, orquestras.third]
]

eventos = eventos_config.map do |descricao, data_evento, igreja, coral, orquestra|
  upsert_record(
    MEvento,
    { descricao: descricao, data_evento: data_evento },
    { g_igreja: igreja, c_coral: coral, o_orquestra: orquestra }
  )
end

eventos.each_with_index do |evento, index|
  musicas.rotate(index).first(3).each_with_index do |musica, ordem|
    upsert_record(
      MEventoMusica,
      { m_evento_id: evento.id, m_musica_id: musica.id },
      { ordem: ordem + 1 }
    )
  end
end

puts "Resumo da carga fake:"
puts "  Paises: #{GPais.count}"
puts "  Estados: #{GEstado.count}"
puts "  Cidades: #{GCidade.count}"
puts "  Igrejas: #{GIgreja.count}"
puts "  Instrumentos: #{GInstrumento.count}"
puts "  Naipes: #{GNaipe.count}"
puts "  Instrumento x naipe: #{GInstrumentoNaipe.count}"
puts "  Pessoas: #{GPessoa.count}"
puts "  Usuarios: #{GUsuario.count}"
puts "  Vinculos pessoa/naipe: #{GPessoaNaipe.count}"
puts "  Musicas: #{MMusica.count}"
puts "  Materiais: #{MMaterial.count}"
puts "  Eventos: #{MEvento.count}"
puts "  Evento-musicas: #{MEventoMusica.count}"
puts "  Perfis: #{GPerfil.active.order(:descricao).pluck(:descricao).join(', ')}"
puts "  Admin principal: #{admin.email}"
puts "  Maestro fake: #{maestro.email}"
puts "  Coristas fake: #{coristas.map(&:email).join(', ')}"

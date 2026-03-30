# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular "g_pais", "g_paises"
  inflect.irregular "g_estado", "g_estados"
  inflect.irregular "g_cidade", "g_cidades"
  inflect.irregular "g_igreja", "g_igrejas"
  inflect.irregular "c_coral", "c_corais"
  inflect.irregular "o_orquestra", "o_orquestras"
  inflect.irregular "g_tipo_pessoa", "g_tipos_pessoa"
  inflect.irregular "g_pessoa", "g_pessoas"
  inflect.irregular "g_usuario", "g_usuarios"
  inflect.irregular "g_perfil", "g_perfis"
  inflect.irregular "g_permissao", "g_permissoes"
  inflect.irregular "g_usuario_perfil", "g_usuario_perfis"
  inflect.irregular "g_perfil_permissao", "g_perfis_permissoes"
  inflect.irregular "g_instrumento", "g_instrumentos"
  inflect.irregular "g_naipe", "g_naipes"
  inflect.irregular "g_pessoa_naipe", "g_pessoa_naipes"
  inflect.irregular "m_musica", "m_musicas"
  inflect.irregular "m_material", "m_materiais"
  inflect.irregular "m_evento", "m_eventos"
  inflect.irregular "m_evento_musica", "m_evento_musicas"
end

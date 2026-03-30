# frozen_string_literal: true

class GPerfilPermissaoSerializer < ActiveModel::Serializer
  attributes :id

  belongs_to :g_perfil
  belongs_to :g_permissao
end

# frozen_string_literal: true

class GPerfilSerializer < ActiveModel::Serializer
  attributes :id, :descricao, :quantidade_usuarios, :quantidade_permissoes

  def quantidade_usuarios
    object.users.loaded? ? object.users.size : object.users.count
  end

  def quantidade_permissoes
    object.g_permissoes.loaded? ? object.g_permissoes.size : object.g_permissoes.count
  end
end

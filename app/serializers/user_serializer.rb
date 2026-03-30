# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  attributes :id, :nome, :email, :cpf, :admin, :g_perfil_id, :primeiro_acesso

  belongs_to :g_perfil
end

# frozen_string_literal: true

class GUsuarioSerializer < ActiveModel::Serializer
  attributes :id, :email, :ativo, :cpf, :nome, :g_perfil_id, :g_pessoa_id
  belongs_to :g_pessoa
end

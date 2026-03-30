# frozen_string_literal: true

class GUsuarioSerializer < ActiveModel::Serializer
  attributes :id, :email, :encrypted_password, :ativo
  belongs_to :g_pessoa
end

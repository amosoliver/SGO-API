# frozen_string_literal: true

class GPessoaSerializer < ActiveModel::Serializer
  attributes :id, :descricao, :email, :ativo
  belongs_to :g_tipo_pessoa
  belongs_to :g_igreja
end

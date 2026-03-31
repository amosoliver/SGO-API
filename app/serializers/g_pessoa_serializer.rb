# frozen_string_literal: true

class GPessoaSerializer < ActiveModel::Serializer
  attributes :id, :descricao, :email, :cpf, :ativo, :g_tipo_pessoa_id, :g_igreja_id
  belongs_to :g_tipo_pessoa
  belongs_to :g_igreja
end

# frozen_string_literal: true

class GIgrejaSerializer < ActiveModel::Serializer
  attributes :id, :descricao, :endereco, :ativo, :g_cidade_id
  belongs_to :g_cidade
end

# frozen_string_literal: true

class GIgrejaSerializer < ActiveModel::Serializer
  attributes :id, :descricao, :endereco, :ativo
  belongs_to :g_cidade
end

# frozen_string_literal: true

class GNaipeSerializer < ActiveModel::Serializer
  attributes :id, :descricao, :ordem
  belongs_to :g_instrumento
end

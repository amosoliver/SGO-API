# frozen_string_literal: true

class OOrquestraSerializer < ActiveModel::Serializer
  attributes :id, :descricao, :ativo
  belongs_to :g_igreja
end

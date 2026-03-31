# frozen_string_literal: true

class OOrquestraSerializer < ActiveModel::Serializer
  attributes :id, :descricao, :ativo, :g_igreja_id
  belongs_to :g_igreja
end

# frozen_string_literal: true

class GCidadeSerializer < ActiveModel::Serializer
  attributes :id, :descricao, :g_estado_id
  belongs_to :g_estado
end

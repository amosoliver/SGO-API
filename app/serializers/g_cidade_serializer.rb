# frozen_string_literal: true

class GCidadeSerializer < ActiveModel::Serializer
  attributes :id, :descricao
  belongs_to :g_estado
end

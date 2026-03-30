# frozen_string_literal: true

class MEventoSerializer < ActiveModel::Serializer
  attributes :id, :descricao, :data_evento
  belongs_to :g_igreja
  belongs_to :c_coral
  belongs_to :o_orquestra
end

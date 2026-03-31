# frozen_string_literal: true

class MEventoSerializer < ActiveModel::Serializer
  attributes :id, :descricao, :data_evento, :g_igreja_id, :c_coral_id, :o_orquestra_id
  belongs_to :g_igreja
  belongs_to :c_coral
  belongs_to :o_orquestra
end

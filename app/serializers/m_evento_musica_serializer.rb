# frozen_string_literal: true

class MEventoMusicaSerializer < ActiveModel::Serializer
  attributes :id, :ordem
  belongs_to :m_evento
  belongs_to :m_musica
end

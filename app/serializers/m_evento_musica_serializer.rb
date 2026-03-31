# frozen_string_literal: true

class MEventoMusicaSerializer < ActiveModel::Serializer
  attributes :id, :ordem, :m_evento_id, :m_musica_id
  belongs_to :m_evento
  belongs_to :m_musica
end

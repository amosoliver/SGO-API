# frozen_string_literal: true

# Associações:
# m_evento
# m_musica


# Atributos:
# integer - ordem

class MEventoMusica < ApplicationRecord
  belongs_to :m_evento
  belongs_to :m_musica

  validates :ordem, presence: true, uniqueness: {
    scope: :m_evento_id,
    conditions: -> { where(deleted_at: nil) },
    message: "ja esta sendo utilizada neste evento"
  }
end

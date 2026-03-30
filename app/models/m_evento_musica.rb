# frozen_string_literal: true

# Associações:
# m_evento
# m_musica


# Atributos:
# integer - ordem

class MEventoMusica < ApplicationRecord
  belongs_to :m_evento
  belongs_to :m_musica
end

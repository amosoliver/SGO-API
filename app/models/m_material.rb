# frozen_string_literal: true

# Associações:
# m_musica
# g_instrumento
# g_naipe


# Atributos:
# string - tipo
# string - descricao
# string - arquivo_url

class MMaterial < ApplicationRecord
  belongs_to :m_musica
  belongs_to :g_instrumento
  belongs_to :g_naipe
end

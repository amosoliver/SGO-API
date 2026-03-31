# frozen_string_literal: true

# Associações:


# Atributos:
# string - descricao
# integer - ordem

class GInstrumento < ApplicationRecord
  has_many :g_instrumentos_naipes, dependent: :destroy
  has_many :g_naipes, through: :g_instrumentos_naipes
  has_many :g_pessoa_naipes, dependent: :destroy
  has_many :m_materiais, through: :g_instrumentos_naipes
end

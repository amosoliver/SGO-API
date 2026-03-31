# frozen_string_literal: true

# Atributos:
# string - descricao

class GNaipe < ApplicationRecord
  has_many :g_instrumentos_naipes, dependent: :destroy
  has_many :g_instrumentos, through: :g_instrumentos_naipes
  has_many :g_pessoa_naipes, dependent: :destroy
  has_many :m_materiais, through: :g_instrumentos_naipes

  validates :descricao, presence: true, uniqueness: { scope: :deleted_at, conditions: -> { where(deleted_at: nil) } }
end

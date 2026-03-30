# frozen_string_literal: true

class GPerfil < ApplicationRecord
  self.table_name = "g_perfis"

  has_many :users, foreign_key: :g_perfil_id, inverse_of: :g_perfil, dependent: :nullify
  has_many :g_perfis_permissoes, dependent: :destroy
  has_many :g_permissoes, through: :g_perfis_permissoes

  scope :active, -> { where(deleted_at: nil) }

  validates :descricao, presence: true, uniqueness: { scope: :deleted_at, conditions: -> { where(deleted_at: nil) } }
end

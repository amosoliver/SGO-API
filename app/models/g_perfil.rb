# frozen_string_literal: true

class GPerfil < ApplicationRecord
  self.table_name = "g_perfis"

  has_many :g_usuario_perfis, dependent: :destroy
  has_many :g_usuarios, through: :g_usuario_perfis
  has_many :g_perfis_permissoes, dependent: :destroy
  has_many :g_permissoes, through: :g_perfis_permissoes

  scope :active, -> { where(deleted_at: nil) }

  validates :descricao, presence: true, uniqueness: { scope: :deleted_at, conditions: -> { where(deleted_at: nil) } }
end

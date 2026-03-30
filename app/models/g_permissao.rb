# frozen_string_literal: true

class GPermissao < ApplicationRecord
  self.table_name = "g_permissoes"

  has_many :g_perfis_permissoes, dependent: :destroy
  has_many :g_perfis, through: :g_perfis_permissoes

  scope :active, -> { where(deleted_at: nil) }
  scope :nao_admin, -> { where(admin: false) }

  validates :controlador, :acao, presence: true
  validates :acao, uniqueness: { scope: %i[controlador deleted_at], conditions: -> { where(deleted_at: nil) } }
end

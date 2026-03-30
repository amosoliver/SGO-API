# frozen_string_literal: true

class GPerfilPermissao < ApplicationRecord
  self.table_name = "g_perfis_permissoes"

  belongs_to :g_perfil
  belongs_to :g_permissao

  scope :active, -> { where(deleted_at: nil) }

  validates :g_permissao_id, uniqueness: { scope: %i[g_perfil_id deleted_at], conditions: -> { where(deleted_at: nil) } }
  validate :nao_permitir_permissao_administrativa

  private

  def nao_permitir_permissao_administrativa
    return unless g_permissao&.admin?

    errors.add(:g_permissao_id, "não pode ser permissão administrativa")
  end
end

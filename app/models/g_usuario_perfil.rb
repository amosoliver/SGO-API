# frozen_string_literal: true

class GUsuarioPerfil < ApplicationRecord
  self.table_name = "g_usuarios_perfis"

  belongs_to :g_usuario
  belongs_to :g_perfil

  scope :active, -> { where(deleted_at: nil) }
end

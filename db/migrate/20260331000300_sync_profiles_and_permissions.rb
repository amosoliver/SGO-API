# frozen_string_literal: true

class SyncProfilesAndPermissions < ActiveRecord::Migration[8.1]
  def up
    PermissionSyncService.new.call
    ProfilePermissionSyncService.new.call
  end

  def down
    GUsuarioPerfil.where(g_perfil_id: GPerfil.where(descricao: %w[ADM MAESTRO CORISTA]).select(:id)).delete_all
    GPerfilPermissao.where(g_perfil_id: GPerfil.where(descricao: %w[ADM MAESTRO CORISTA]).select(:id)).delete_all
    GPerfil.where(descricao: %w[ADM MAESTRO CORISTA]).delete_all
  end
end

# frozen_string_literal: true

class ProfilePermissionSyncService
  PROFILE_RULES = {
    "ADM" => :full_access?,
    "MAESTRO" => :full_access?,
    "CORISTA" => :corista_access?
  }.freeze

  CORISTA_ALLOWED_ACTIONS = %w[index show me logout update_password get_permissions].freeze

  def call(assign_admin_to: nil)
    perfis = ensure_profiles!

    GPermissao.active.find_each do |permission|
      perfis.each do |perfil_name, perfil|
        upsert_permission!(perfil, permission) if send(PROFILE_RULES.fetch(perfil_name), permission)
      end
    end

    perfis.each_value { |perfil| deactivate_removed_permissions!(perfil) }
    assign_admin_profile!(perfis["ADM"], assign_admin_to)
  end

  private

  def ensure_profiles!
    PROFILE_RULES.keys.index_with do |descricao|
      perfil = GPerfil.unscoped.find_or_initialize_by(descricao: descricao)
      perfil.deleted_at = nil
      perfil.save! if perfil.new_record? || perfil.changed?
      perfil
    end
  end

  def full_access?(_permission)
    true
  end

  def corista_access?(permission)
    return true if permission.controlador == "auth_controller" && CORISTA_ALLOWED_ACTIONS.include?(permission.acao)

    CORISTA_ALLOWED_ACTIONS.include?(permission.acao)
  end

  def upsert_permission!(perfil, permission)
    record = GPerfilPermissao.unscoped.find_or_initialize_by(g_perfil_id: perfil.id, g_permissao_id: permission.id)
    record.deleted_at = nil
    record.save! if record.new_record? || record.changed?
  end

  def deactivate_removed_permissions!(perfil)
    allowed_ids = GPermissao.active.select { |permission| send(PROFILE_RULES.fetch(perfil.descricao), permission) }.map(&:id)
    perfil.g_perfis_permissoes.active.where.not(g_permissao_id: allowed_ids).update_all(deleted_at: Time.current, updated_at: Time.current)
  end

  def assign_admin_profile!(perfil, user)
    target_user = user || GUsuario.active.order(:id).first
    return if target_user.blank?

    GUsuarioPerfil.active.where(g_usuario_id: target_user.id).update_all(deleted_at: Time.current, updated_at: Time.current)
    record = GUsuarioPerfil.unscoped.find_or_initialize_by(g_usuario_id: target_user.id, g_perfil_id: perfil.id)
    record.deleted_at = nil
    record.save!
  end
end

# frozen_string_literal: true

class PermissionSyncService
  API_CONTROLLER_PREFIX = "api/v1/".freeze

  def call
    permissions_map = build_permissions_map
    sync_permissions!(permissions_map)
  end

  private

  def build_permissions_map
    Rails.application.routes.routes.each_with_object({}) do |route, result|
      controller = route.defaults[:controller].to_s
      action = route.defaults[:action].to_s

      next if controller.blank? || action.blank?
      next unless controller.start_with?(API_CONTROLLER_PREFIX)

      controller_name = "#{controller.split('/').last}_controller"
      result[controller_name] ||= []
      result[controller_name] << action
    end.transform_values { |actions| actions.uniq.sort }
  end

  def sync_permissions!(permissions_map)
    active_keys = []

    permissions_map.each do |controller_key, actions|
      existing_permissions = GPermissao.unscoped.where(controlador: controller_key).index_by(&:acao)

      actions.each do |action|
        active_keys << [controller_key, action]
        permission = existing_permissions[action] || GPermissao.new(controlador: controller_key, acao: action)
        permission.assign_attributes(
          nome_controlador: controller_key.delete_suffix("_controller").humanize,
          nome_acao: action.humanize,
          deleted_at: nil
        )
        permission.save! if permission.new_record? || permission.changed?
      end
    end

    GPermissao.active.find_each do |permission|
      next if active_keys.include?([permission.controlador, permission.acao])

      permission.update!(deleted_at: Time.current)
    end
  end
end

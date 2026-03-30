# frozen_string_literal: true

namespace :menu do
  desc "Mapeia controllers e sincroniza permissões na tabela g_permissoes"
  task generate: :environment do
    controllers_path = Rails.root.join("app/controllers/api/v1")
    controllers_data = {}

    Dir.glob(controllers_path.join("**/*_controller.rb")).sort.each do |controller_path|
      relative_path = Pathname(controller_path).relative_path_from(controllers_path).to_s
      basename = File.basename(relative_path, "_controller.rb").underscore
      namespace_parts = File.dirname(relative_path) == "." ? [] : File.dirname(relative_path).split("/")
      class_name = (["Api", "V1"] + namespace_parts.map(&:camelize) + ["#{basename.camelize}Controller"]).join("::")

      begin
        controller_class = class_name.constantize
      rescue NameError
        next
      end

      controllers_data[basename] = controller_class.public_instance_methods(false).reject { |m| m.to_s.end_with?("?") }.map(&:to_s).sort
    end

    controllers_data.each do |controller_basename, actions|
      controller_key = "#{controller_basename}_controller"
      existing = GPermissao.unscoped.where(controlador: controller_key, deleted_at: nil).index_by(&:acao)

      actions.each do |action|
        permission = existing[action]
        if permission.present?
          permission.update_columns(
            nome_controlador: controller_basename.humanize,
            nome_acao: action.humanize,
            updated_at: Time.current
          )
        else
          GPermissao.create!(
            controlador: controller_key,
            acao: action,
            nome_controlador: controller_basename.humanize,
            nome_acao: action.humanize
          )
        end
      end

      removed_actions = existing.keys - actions
      next if removed_actions.empty?

      GPermissao.where(controlador: controller_key, acao: removed_actions, deleted_at: nil).update_all(deleted_at: Time.current)
    end
  end
end

# frozen_string_literal: true

Rails.application.config.after_initialize do
  next unless ENV.fetch("AUTO_SYNC_PERMISSIONS", "true") == "true"
  next unless defined?(ActiveRecord::Base)

  begin
    next unless ActiveRecord::Base.connection.data_source_exists?("g_permissoes")

    PermissionSyncService.new.call
    ProfilePermissionSyncService.new.call
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad
    nil
  end
end

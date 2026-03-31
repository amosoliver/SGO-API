# frozen_string_literal: true

namespace :menu do
  desc "Mapeia controllers e sincroniza permissões na tabela g_permissoes"
  task generate: :environment do
    PermissionSyncService.new.call
    ProfilePermissionSyncService.new.call
  end
end

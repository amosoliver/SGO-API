# frozen_string_literal: true

Rails.application.load_tasks if Rake::Task.tasks.empty?
Rake::Task["menu:generate"].reenable
Rake::Task["menu:generate"].invoke

admin_email = ENV.fetch("ADMIN_EMAIL", "admin@sgo.local")
admin_password = ENV.fetch("ADMIN_PASSWORD", "Admin@123")

admin = User.find_or_initialize_by(email: admin_email)
admin.nome = ENV.fetch("ADMIN_NOME", "Administrador")
admin.password = admin_password
admin.password_confirmation = admin_password
admin.admin = true
admin.primeiro_acesso = false
admin.deleted_at = nil
admin.save!

puts "Admin bootstrap pronto: #{admin.email}"
puts "Permissões sincronizadas: #{GPermissao.count}"

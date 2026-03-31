# frozen_string_literal: true

class MoveGUsuariosPerfisToGUsuarioReference < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :g_usuarios_perfis, :users if foreign_key_exists?(:g_usuarios_perfis, :users)

    if column_exists?(:g_usuarios_perfis, :user_id) && !column_exists?(:g_usuarios_perfis, :g_usuario_id)
      rename_column :g_usuarios_perfis, :user_id, :g_usuario_id
    end

    add_foreign_key :g_usuarios_perfis, :g_usuarios, column: :g_usuario_id unless foreign_key_exists?(:g_usuarios_perfis, :g_usuarios, column: :g_usuario_id)
    add_index :g_usuarios_perfis, :g_usuario_id unless index_exists?(:g_usuarios_perfis, :g_usuario_id)
  end

  def down
    remove_foreign_key :g_usuarios_perfis, column: :g_usuario_id if foreign_key_exists?(:g_usuarios_perfis, column: :g_usuario_id)
    remove_index :g_usuarios_perfis, :g_usuario_id if index_exists?(:g_usuarios_perfis, :g_usuario_id)

    if column_exists?(:g_usuarios_perfis, :g_usuario_id) && !column_exists?(:g_usuarios_perfis, :user_id)
      rename_column :g_usuarios_perfis, :g_usuario_id, :user_id
    end

    add_foreign_key :g_usuarios_perfis, :users, column: :user_id unless foreign_key_exists?(:g_usuarios_perfis, :users, column: :user_id)
    add_index :g_usuarios_perfis, :user_id unless index_exists?(:g_usuarios_perfis, :user_id)
  end
end

# frozen_string_literal: true

class CreateGUsuariosPerfis < ActiveRecord::Migration[8.1]
  def change
    create_table :g_usuarios_perfis do |t|
      t.references :user, null: false, foreign_key: true
      t.references :g_perfil, null: false, foreign_key: { to_table: :g_perfis }
      t.string :created_by
      t.string :updated_by
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :g_usuarios_perfis, :deleted_at
  end
end

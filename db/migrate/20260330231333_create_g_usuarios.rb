# frozen_string_literal: true

class CreateGUsuarios < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:g_usuarios)
      create_table :g_usuarios do |t|
        t.references :g_pessoa, foreign_key: true
        t.string :email
        t.string :encrypted_password
        t.boolean :ativo
        t.string :created_by
        t.string :updated_by
        t.datetime :deleted_at
        t.timestamps
      end
    end
  end

  def down
    drop_table :g_usuarios if table_exists?(:g_usuarios)
  end
end

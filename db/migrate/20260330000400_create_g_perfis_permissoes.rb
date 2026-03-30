# frozen_string_literal: true

class CreateGPerfisPermissoes < ActiveRecord::Migration[8.1]
  def change
    create_table :g_perfis_permissoes do |t|
      t.references :g_perfil, null: false, foreign_key: { to_table: :g_perfis }
      t.references :g_permissao, null: false, foreign_key: { to_table: :g_permissoes }
      t.string :created_by
      t.string :updated_by
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :g_perfis_permissoes, :deleted_at
  end
end

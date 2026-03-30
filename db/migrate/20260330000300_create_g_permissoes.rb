# frozen_string_literal: true

class CreateGPermissoes < ActiveRecord::Migration[8.1]
  def change
    create_table :g_permissoes do |t|
      t.string :controlador, null: false
      t.string :acao, null: false
      t.string :nome_controlador
      t.string :nome_acao
      t.boolean :admin, default: false, null: false
      t.string :created_by
      t.string :updated_by
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :g_permissoes, %i[controlador acao], unique: true
    add_index :g_permissoes, :deleted_at
  end
end

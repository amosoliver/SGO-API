# frozen_string_literal: true

class CreateGPerfis < ActiveRecord::Migration[8.1]
  def change
    create_table :g_perfis do |t|
      t.string :descricao, null: false
      t.string :created_by
      t.string :updated_by
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :g_perfis, :deleted_at
  end
end

# frozen_string_literal: true

class CreateGCidades < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:g_cidades)
      create_table :g_cidades do |t|
        t.references :g_estado, foreign_key: true
        t.string :descricao
        t.string :created_by
        t.string :updated_by
        t.datetime :deleted_at
        t.timestamps
      end
    end
  end

  def down
    drop_table :g_cidades if table_exists?(:g_cidades)
  end
end

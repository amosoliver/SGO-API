# frozen_string_literal: true

class CreateGEstados < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:g_estados)
      create_table :g_estados do |t|
        t.references :g_pais, foreign_key: true
        t.string :descricao
        t.string :sigla
        t.string :created_by
        t.string :updated_by
        t.datetime :deleted_at
        t.timestamps
      end
    end
  end

  def down
    drop_table :g_estados if table_exists?(:g_estados)
  end
end

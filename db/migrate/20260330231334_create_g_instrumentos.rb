# frozen_string_literal: true

class CreateGInstrumentos < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:g_instrumentos)
      create_table :g_instrumentos do |t|
        t.string :descricao
        t.integer :ordem
        t.string :created_by
        t.string :updated_by
        t.datetime :deleted_at
        t.timestamps
      end
    end
  end

  def down
    drop_table :g_instrumentos if table_exists?(:g_instrumentos)
  end
end

# frozen_string_literal: true

class CreateGPaises < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:g_paises)
      create_table :g_paises do |t|
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
    drop_table :g_paises if table_exists?(:g_paises)
  end
end

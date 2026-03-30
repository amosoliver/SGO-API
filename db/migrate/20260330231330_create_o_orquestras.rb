# frozen_string_literal: true

class CreateOOrquestras < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:o_orquestras)
      create_table :o_orquestras do |t|
        t.string :descricao
        t.references :g_igreja, foreign_key: true
        t.boolean :ativo
        t.string :created_by
        t.string :updated_by
        t.datetime :deleted_at
        t.timestamps
      end
    end
  end

  def down
    drop_table :o_orquestras if table_exists?(:o_orquestras)
  end
end

# frozen_string_literal: true

class CreateGIgrejas < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:g_igrejas)
      create_table :g_igrejas do |t|
        t.string :descricao
        t.string :endereco
        t.references :g_cidade, foreign_key: true
        t.boolean :ativo
        t.string :created_by
        t.string :updated_by
        t.datetime :deleted_at
        t.timestamps
      end
    end
  end

  def down
    drop_table :g_igrejas if table_exists?(:g_igrejas)
  end
end

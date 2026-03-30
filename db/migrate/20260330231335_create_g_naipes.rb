# frozen_string_literal: true

class CreateGNaipes < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:g_naipes)
      create_table :g_naipes do |t|
        t.references :g_instrumento, foreign_key: true
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
    drop_table :g_naipes if table_exists?(:g_naipes)
  end
end

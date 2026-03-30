# frozen_string_literal: true

class CreateGPessoaNaipes < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:g_pessoa_naipes)
      create_table :g_pessoa_naipes do |t|
        t.references :g_pessoa, foreign_key: true
        t.references :g_instrumento, foreign_key: true
        t.references :g_naipe, foreign_key: true
        t.boolean :principal
        t.string :posicao
        t.string :created_by
        t.string :updated_by
        t.datetime :deleted_at
        t.timestamps
      end
    end
  end

  def down
    drop_table :g_pessoa_naipes if table_exists?(:g_pessoa_naipes)
  end
end

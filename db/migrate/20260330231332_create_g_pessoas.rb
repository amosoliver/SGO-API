# frozen_string_literal: true

class CreateGPessoas < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:g_pessoas)
      create_table :g_pessoas do |t|
        t.string :descricao
        t.string :email
        t.references :g_tipo_pessoa, foreign_key: true
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
    drop_table :g_pessoas if table_exists?(:g_pessoas)
  end
end

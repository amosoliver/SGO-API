# frozen_string_literal: true

class CreateGTiposPessoa < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:g_tipos_pessoa)
      create_table :g_tipos_pessoa do |t|
        t.string :descricao
        t.string :created_by
        t.string :updated_by
        t.datetime :deleted_at
        t.timestamps
      end
    end
  end

  def down
    drop_table :g_tipos_pessoa if table_exists?(:g_tipos_pessoa)
  end
end

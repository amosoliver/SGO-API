# frozen_string_literal: true

class CreateCCorais < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:c_corais)
      create_table :c_corais do |t|
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
    drop_table :c_corais if table_exists?(:c_corais)
  end
end

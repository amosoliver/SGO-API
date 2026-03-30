# frozen_string_literal: true

class CreateMMateriais < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:m_materiais)
      create_table :m_materiais do |t|
        t.references :m_musica, foreign_key: true
        t.references :g_instrumento, foreign_key: true
        t.references :g_naipe, foreign_key: true
        t.string :tipo
        t.string :descricao
        t.string :arquivo_url
        t.string :created_by
        t.string :updated_by
        t.datetime :deleted_at
        t.timestamps
      end
    end
  end

  def down
    drop_table :m_materiais if table_exists?(:m_materiais)
  end
end

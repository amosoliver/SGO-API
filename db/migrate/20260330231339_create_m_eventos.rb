# frozen_string_literal: true

class CreateMEventos < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:m_eventos)
      create_table :m_eventos do |t|
        t.string :descricao
        t.datetime :data_evento
        t.references :g_igreja, foreign_key: true
        t.references :c_coral, foreign_key: true
        t.references :o_orquestra, foreign_key: true
        t.string :created_by
        t.string :updated_by
        t.datetime :deleted_at
        t.timestamps
      end
    end
  end

  def down
    drop_table :m_eventos if table_exists?(:m_eventos)
  end
end

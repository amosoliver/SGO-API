# frozen_string_literal: true

class CreateMMusicas < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:m_musicas)
      create_table :m_musicas do |t|
        t.string :descricao
        t.string :tonalidade
        t.integer :bpm
        t.integer :duracao
        t.string :created_by
        t.string :updated_by
        t.datetime :deleted_at
        t.timestamps
      end
    end
  end

  def down
    drop_table :m_musicas if table_exists?(:m_musicas)
  end
end

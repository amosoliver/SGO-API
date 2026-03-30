# frozen_string_literal: true

class CreateMEventoMusicas < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:m_evento_musicas)
      create_table :m_evento_musicas do |t|
        t.references :m_evento, foreign_key: true
        t.references :m_musica, foreign_key: true
        t.integer :ordem
        t.string :created_by
        t.string :updated_by
        t.datetime :deleted_at
        t.timestamps
      end
    end
  end

  def down
    drop_table :m_evento_musicas if table_exists?(:m_evento_musicas)
  end
end

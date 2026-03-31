# frozen_string_literal: true

class AddUniqueIndexToMEventoMusicasOrdemPerEvento < ActiveRecord::Migration[8.1]
  def change
    add_index :m_evento_musicas,
              %i[m_evento_id ordem],
              unique: true,
              where: "deleted_at IS NULL",
              name: "index_m_evento_musicas_on_evento_id_and_ordem_unique"
  end
end

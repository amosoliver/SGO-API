# frozen_string_literal: true

class ChangeMMusicasDuracaoToTime < ActiveRecord::Migration[8.1]
  def up
    add_column :m_musicas, :duracao_time, :time

    execute <<~SQL
      UPDATE m_musicas
      SET duracao_time = make_time(0, COALESCE(duracao, 0) / 60, COALESCE(duracao, 0) % 60)
      WHERE duracao IS NOT NULL
    SQL

    remove_column :m_musicas, :duracao
    rename_column :m_musicas, :duracao_time, :duracao
  end

  def down
    add_column :m_musicas, :duracao_integer, :integer

    execute <<~SQL
      UPDATE m_musicas
      SET duracao_integer = EXTRACT(HOUR FROM duracao)::integer * 3600
                          + EXTRACT(MINUTE FROM duracao)::integer * 60
                          + EXTRACT(SECOND FROM duracao)::integer
      WHERE duracao IS NOT NULL
    SQL

    remove_column :m_musicas, :duracao
    rename_column :m_musicas, :duracao_integer, :duracao
  end
end

# frozen_string_literal: true

class ReplaceMMateriaisInstrumentoAndNaipeWithRelacao < ActiveRecord::Migration[8.0]
  class MigrationMMaterial < ApplicationRecord
    self.table_name = "m_materiais"
  end

  class MigrationGInstrumentoNaipe < ApplicationRecord
    self.table_name = "g_instrumentos_naipes"
  end

  def up
    add_reference :m_materiais, :g_instrumento_naipe, foreign_key: true unless column_exists?(:m_materiais, :g_instrumento_naipe_id)

    say_with_time "Migrando materiais para g_instrumento_naipe" do
      MigrationMMaterial.reset_column_information

      MigrationMMaterial.find_each do |material|
        next if material[:g_instrumento_naipe_id].present?
        next if material[:g_instrumento_id].blank? || material[:g_naipe_id].blank?

        relacao_id = MigrationGInstrumentoNaipe.where(
          g_instrumento_id: material[:g_instrumento_id],
          g_naipe_id: material[:g_naipe_id]
        ).pick(:id)

        next if relacao_id.blank?

        material.update_columns(g_instrumento_naipe_id: relacao_id, updated_at: Time.current)
      end
    end

    remove_reference :m_materiais, :g_instrumento, foreign_key: true if column_exists?(:m_materiais, :g_instrumento_id)
    remove_reference :m_materiais, :g_naipe, foreign_key: true if column_exists?(:m_materiais, :g_naipe_id)
  end

  def down
    add_reference :m_materiais, :g_instrumento, foreign_key: true unless column_exists?(:m_materiais, :g_instrumento_id)
    add_reference :m_materiais, :g_naipe, foreign_key: true unless column_exists?(:m_materiais, :g_naipe_id)

    say_with_time "Restaurando instrumento e naipe em materiais" do
      MigrationMMaterial.reset_column_information

      MigrationMMaterial.find_each do |material|
        next if material[:g_instrumento_naipe_id].blank?

        relacao = MigrationGInstrumentoNaipe.find_by(id: material[:g_instrumento_naipe_id])
        next if relacao.blank?

        material.update_columns(
          g_instrumento_id: relacao.g_instrumento_id,
          g_naipe_id: relacao.g_naipe_id,
          updated_at: Time.current
        )
      end
    end

    remove_reference :m_materiais, :g_instrumento_naipe, foreign_key: true if column_exists?(:m_materiais, :g_instrumento_naipe_id)
  end
end

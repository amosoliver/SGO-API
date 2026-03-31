# frozen_string_literal: true

class NormalizeGNaipesAndCreateGInstrumentosNaipes < ActiveRecord::Migration[8.1]
  class MigrationGNaipe < ApplicationRecord
    self.table_name = "g_naipes"
  end

  class MigrationGPessoaNaipe < ApplicationRecord
    self.table_name = "g_pessoa_naipes"
  end

  class MigrationMMaterial < ApplicationRecord
    self.table_name = "m_materiais"
  end

  class MigrationGInstrumentoNaipe < ApplicationRecord
    self.table_name = "g_instrumentos_naipes"
  end

  def up
    create_table :g_instrumentos_naipes do |t|
      t.references :g_instrumento, null: false, foreign_key: true
      t.references :g_naipe, null: false, foreign_key: true
      t.integer :ordem
      t.string :created_by
      t.string :updated_by
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :g_instrumentos_naipes, %i[g_instrumento_id g_naipe_id], unique: true, name: "index_g_instrumentos_naipes_on_instrumento_and_naipe"
    add_index :g_instrumentos_naipes, :deleted_at

    migrate_existing_naipes!

    remove_foreign_key :g_naipes, :g_instrumentos if foreign_key_exists?(:g_naipes, :g_instrumentos)
    remove_index :g_naipes, :g_instrumento_id if index_exists?(:g_naipes, :g_instrumento_id)
    remove_column :g_naipes, :g_instrumento_id if column_exists?(:g_naipes, :g_instrumento_id)
    remove_column :g_naipes, :ordem if column_exists?(:g_naipes, :ordem)
  end

  def down
    add_reference :g_naipes, :g_instrumento, foreign_key: true unless column_exists?(:g_naipes, :g_instrumento_id)
    add_column :g_naipes, :ordem, :integer unless column_exists?(:g_naipes, :ordem)

    MigrationGInstrumentoNaipe.reset_column_information
    MigrationGNaipe.reset_column_information

    MigrationGInstrumentoNaipe.find_each do |relacao|
      naipe = MigrationGNaipe.find(relacao.g_naipe_id)
      next if naipe.g_instrumento_id.present?

      naipe.update_columns(g_instrumento_id: relacao.g_instrumento_id, ordem: relacao.ordem)
    end

    drop_table :g_instrumentos_naipes, if_exists: true
  end

  private

  def migrate_existing_naipes!
    say_with_time "Normalizando naipes e migrando relacoes instrumento x naipe" do
      MigrationGNaipe.reset_column_information
      MigrationGInstrumentoNaipe.reset_column_information
      MigrationGPessoaNaipe.reset_column_information
      MigrationMMaterial.reset_column_information

      old_naipes = MigrationGNaipe.unscoped.order(:id).map do |naipe|
        {
          id: naipe.id,
          descricao: naipe.descricao,
          g_instrumento_id: naipe[:g_instrumento_id],
          ordem: naipe[:ordem],
          deleted_at: naipe.deleted_at
        }
      end

      canonical_ids = {}
      old_to_new = {}

      old_naipes.each do |old_naipe|
        canonical_id = canonical_ids[old_naipe[:descricao]]

        unless canonical_id
          canonical_ids[old_naipe[:descricao]] = old_naipe[:id]
          canonical_id = old_naipe[:id]
          MigrationGNaipe.where(id: canonical_id).update_all(deleted_at: nil, updated_at: Time.current)
        end

        old_to_new[old_naipe[:id]] = canonical_id

        MigrationGInstrumentoNaipe.find_or_create_by!(
          g_instrumento_id: old_naipe[:g_instrumento_id],
          g_naipe_id: canonical_id
        ) do |relacao|
          relacao.ordem = old_naipe[:ordem]
          relacao.deleted_at = old_naipe[:deleted_at]
        end
      end

      old_to_new.each do |old_id, new_id|
        next if old_id == new_id

        MigrationGPessoaNaipe.where(g_naipe_id: old_id).update_all(g_naipe_id: new_id, updated_at: Time.current)
        MigrationMMaterial.where(g_naipe_id: old_id).update_all(g_naipe_id: new_id, updated_at: Time.current)
        MigrationGNaipe.where(id: old_id).delete_all
      end
    end
  end
end

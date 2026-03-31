# frozen_string_literal: true

class AddAuthFieldsToGUsuariosAndCpfToGPessoas < ActiveRecord::Migration[8.1]
  def change
    add_column :g_pessoas, :cpf, :string unless column_exists?(:g_pessoas, :cpf)
    add_index :g_pessoas, :cpf, unique: true unless index_exists?(:g_pessoas, :cpf)

    change_table :g_usuarios, bulk: true do |t|
      t.string :refresh_token unless column_exists?(:g_usuarios, :refresh_token)
      t.string :token_primeiro_acesso unless column_exists?(:g_usuarios, :token_primeiro_acesso)
      t.boolean :primeiro_acesso, default: false, null: false unless column_exists?(:g_usuarios, :primeiro_acesso)
    end
  end
end

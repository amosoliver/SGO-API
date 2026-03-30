# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :nome
      t.string :cpf
      t.datetime :deleted_at
      t.boolean :admin, default: false, null: false
      t.bigint :g_perfil_id
      t.string :refresh_token
      t.string :token_primeiro_acesso
      t.boolean :primeiro_acesso, default: false, null: false
      t.boolean :bloqueado, default: false, null: false
      t.datetime :data_bloqueio
      t.string :motivo_bloqueio
      t.datetime :data_ultimo_acesso
      t.integer :tentativas_acesso, default: 0, null: false
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :g_perfil_id
  end
end

# frozen_string_literal: true

class CreateTestGUsuario < ActiveRecord::Migration[8.1]
  class MigrationGPessoa < ApplicationRecord
    self.table_name = "g_pessoas"
  end

  class MigrationGUsuario < ApplicationRecord
    self.table_name = "g_usuarios"
  end

  def up
    pessoa = MigrationGPessoa.find_or_initialize_by(cpf: "12345678901")
    pessoa.descricao = "Usuario Teste"
    pessoa.email = "teste@sgo.local"
    pessoa.ativo = true if pessoa.has_attribute?(:ativo)
    pessoa.save!

    usuario = MigrationGUsuario.find_or_initialize_by(email: "teste@sgo.local")
    usuario.g_pessoa_id = pessoa.id
    usuario.encrypted_password = BCrypt::Password.create("102030").to_s
    usuario.ativo = true if usuario.has_attribute?(:ativo)
    usuario.deleted_at = nil if usuario.has_attribute?(:deleted_at)
    usuario.primeiro_acesso = false if usuario.has_attribute?(:primeiro_acesso)
    usuario.refresh_token = nil if usuario.has_attribute?(:refresh_token)
    usuario.token_primeiro_acesso = nil if usuario.has_attribute?(:token_primeiro_acesso)
    usuario.save!
  end

  def down
    usuario = MigrationGUsuario.find_by(email: "teste@sgo.local")
    pessoa = MigrationGPessoa.find_by(cpf: "12345678901")

    usuario&.destroy!
    pessoa&.destroy!
  end
end

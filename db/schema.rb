# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_31_043000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "c_corais", force: :cascade do |t|
    t.boolean "ativo"
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.string "descricao"
    t.bigint "g_igreja_id"
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["g_igreja_id"], name: "index_c_corais_on_g_igreja_id"
  end

  create_table "g_cidades", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.string "descricao"
    t.bigint "g_estado_id"
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["g_estado_id"], name: "index_g_cidades_on_g_estado_id"
  end

  create_table "g_estados", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.string "descricao"
    t.bigint "g_pais_id"
    t.string "sigla"
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["g_pais_id"], name: "index_g_estados_on_g_pais_id"
  end

  create_table "g_igrejas", force: :cascade do |t|
    t.boolean "ativo"
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.string "descricao"
    t.string "endereco"
    t.bigint "g_cidade_id"
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["g_cidade_id"], name: "index_g_igrejas_on_g_cidade_id"
  end

  create_table "g_instrumentos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.string "descricao"
    t.integer "ordem"
    t.datetime "updated_at", null: false
    t.string "updated_by"
  end

  create_table "g_instrumentos_naipes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.bigint "g_instrumento_id", null: false
    t.bigint "g_naipe_id", null: false
    t.integer "ordem"
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["deleted_at"], name: "index_g_instrumentos_naipes_on_deleted_at"
    t.index ["g_instrumento_id", "g_naipe_id"], name: "index_g_instrumentos_naipes_on_instrumento_and_naipe", unique: true
    t.index ["g_instrumento_id"], name: "index_g_instrumentos_naipes_on_g_instrumento_id"
    t.index ["g_naipe_id"], name: "index_g_instrumentos_naipes_on_g_naipe_id"
  end

  create_table "g_naipes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.string "descricao"
    t.datetime "updated_at", null: false
    t.string "updated_by"
  end

  create_table "g_paises", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.string "descricao"
    t.string "sigla"
    t.datetime "updated_at", null: false
    t.string "updated_by"
  end

  create_table "g_perfis", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.string "descricao", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["deleted_at"], name: "index_g_perfis_on_deleted_at"
  end

  create_table "g_perfis_permissoes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.bigint "g_perfil_id", null: false
    t.bigint "g_permissao_id", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["deleted_at"], name: "index_g_perfis_permissoes_on_deleted_at"
    t.index ["g_perfil_id"], name: "index_g_perfis_permissoes_on_g_perfil_id"
    t.index ["g_permissao_id"], name: "index_g_perfis_permissoes_on_g_permissao_id"
  end

  create_table "g_permissoes", force: :cascade do |t|
    t.string "acao", null: false
    t.boolean "admin", default: false, null: false
    t.string "controlador", null: false
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.string "nome_acao"
    t.string "nome_controlador"
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["controlador", "acao"], name: "index_g_permissoes_on_controlador_and_acao", unique: true
    t.index ["deleted_at"], name: "index_g_permissoes_on_deleted_at"
  end

  create_table "g_pessoa_naipes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.bigint "g_instrumento_id"
    t.bigint "g_naipe_id"
    t.bigint "g_pessoa_id"
    t.string "posicao"
    t.boolean "principal"
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["g_instrumento_id"], name: "index_g_pessoa_naipes_on_g_instrumento_id"
    t.index ["g_naipe_id"], name: "index_g_pessoa_naipes_on_g_naipe_id"
    t.index ["g_pessoa_id"], name: "index_g_pessoa_naipes_on_g_pessoa_id"
  end

  create_table "g_pessoas", force: :cascade do |t|
    t.boolean "ativo"
    t.string "cpf"
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.string "descricao"
    t.string "email"
    t.bigint "g_igreja_id"
    t.bigint "g_tipo_pessoa_id"
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["cpf"], name: "index_g_pessoas_on_cpf", unique: true
    t.index ["g_igreja_id"], name: "index_g_pessoas_on_g_igreja_id"
    t.index ["g_tipo_pessoa_id"], name: "index_g_pessoas_on_g_tipo_pessoa_id"
  end

  create_table "g_tipos_pessoa", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.string "descricao"
    t.datetime "updated_at", null: false
    t.string "updated_by"
  end

  create_table "g_usuarios", force: :cascade do |t|
    t.boolean "ativo"
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.string "email"
    t.string "encrypted_password"
    t.bigint "g_pessoa_id"
    t.boolean "primeiro_acesso", default: false, null: false
    t.string "refresh_token"
    t.string "token_primeiro_acesso"
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["g_pessoa_id"], name: "index_g_usuarios_on_g_pessoa_id"
  end

  create_table "g_usuarios_perfis", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.bigint "g_perfil_id", null: false
    t.bigint "g_usuario_id", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["deleted_at"], name: "index_g_usuarios_perfis_on_deleted_at"
    t.index ["g_perfil_id"], name: "index_g_usuarios_perfis_on_g_perfil_id"
    t.index ["g_usuario_id"], name: "index_g_usuarios_perfis_on_g_usuario_id"
  end

  create_table "m_evento_musicas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.bigint "m_evento_id"
    t.bigint "m_musica_id"
    t.integer "ordem"
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["m_evento_id"], name: "index_m_evento_musicas_on_m_evento_id"
    t.index ["m_musica_id"], name: "index_m_evento_musicas_on_m_musica_id"
  end

  create_table "m_eventos", force: :cascade do |t|
    t.bigint "c_coral_id"
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "data_evento"
    t.datetime "deleted_at"
    t.string "descricao"
    t.bigint "g_igreja_id"
    t.bigint "o_orquestra_id"
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["c_coral_id"], name: "index_m_eventos_on_c_coral_id"
    t.index ["g_igreja_id"], name: "index_m_eventos_on_g_igreja_id"
    t.index ["o_orquestra_id"], name: "index_m_eventos_on_o_orquestra_id"
  end

  create_table "m_materiais", force: :cascade do |t|
    t.string "arquivo_url"
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.string "descricao"
    t.bigint "g_instrumento_naipe_id"
    t.bigint "m_musica_id"
    t.string "tipo"
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["g_instrumento_naipe_id"], name: "index_m_materiais_on_g_instrumento_naipe_id"
    t.index ["m_musica_id"], name: "index_m_materiais_on_m_musica_id"
  end

  create_table "m_musicas", force: :cascade do |t|
    t.integer "bpm"
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.string "descricao"
    t.time "duracao"
    t.string "tonalidade"
    t.datetime "updated_at", null: false
    t.string "updated_by"
  end

  create_table "o_orquestras", force: :cascade do |t|
    t.boolean "ativo"
    t.datetime "created_at", null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.string "descricao"
    t.bigint "g_igreja_id"
    t.datetime "updated_at", null: false
    t.string "updated_by"
    t.index ["g_igreja_id"], name: "index_o_orquestras_on_g_igreja_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.boolean "bloqueado", default: false, null: false
    t.string "cpf"
    t.datetime "created_at", null: false
    t.datetime "data_bloqueio"
    t.datetime "data_ultimo_acesso"
    t.datetime "deleted_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.bigint "g_perfil_id"
    t.string "motivo_bloqueio"
    t.string "nome"
    t.boolean "primeiro_acesso", default: false, null: false
    t.string "refresh_token"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "tentativas_acesso", default: 0, null: false
    t.string "token_primeiro_acesso"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["g_perfil_id"], name: "index_users_on_g_perfil_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "c_corais", "g_igrejas"
  add_foreign_key "g_cidades", "g_estados"
  add_foreign_key "g_estados", "g_paises"
  add_foreign_key "g_igrejas", "g_cidades"
  add_foreign_key "g_instrumentos_naipes", "g_instrumentos"
  add_foreign_key "g_instrumentos_naipes", "g_naipes"
  add_foreign_key "g_perfis_permissoes", "g_perfis"
  add_foreign_key "g_perfis_permissoes", "g_permissoes"
  add_foreign_key "g_pessoa_naipes", "g_instrumentos"
  add_foreign_key "g_pessoa_naipes", "g_naipes"
  add_foreign_key "g_pessoa_naipes", "g_pessoas"
  add_foreign_key "g_pessoas", "g_igrejas"
  add_foreign_key "g_pessoas", "g_tipos_pessoa"
  add_foreign_key "g_usuarios", "g_pessoas"
  add_foreign_key "g_usuarios_perfis", "g_perfis"
  add_foreign_key "g_usuarios_perfis", "g_usuarios"
  add_foreign_key "m_evento_musicas", "m_eventos"
  add_foreign_key "m_evento_musicas", "m_musicas"
  add_foreign_key "m_eventos", "c_corais"
  add_foreign_key "m_eventos", "g_igrejas"
  add_foreign_key "m_eventos", "o_orquestras"
  add_foreign_key "m_materiais", "g_instrumentos_naipes"
  add_foreign_key "m_materiais", "m_musicas"
  add_foreign_key "o_orquestras", "g_igrejas"
end

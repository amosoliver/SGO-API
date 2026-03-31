# frozen_string_literal: true

class GUsuarioCreateService
  def initialize(payload)
    @payload = payload
  end

  def call
    g_usuario = GUsuario.new(base_usuario_attributes)

    GUsuario.transaction do
      g_usuario.g_pessoa = resolve_g_pessoa!(g_usuario)
      g_usuario.save!
      sync_profile!(g_usuario)
    end

    Result.success(g_usuario, :created)
  rescue ActiveRecord::RecordInvalid => e
    Result.failure(e.record.errors.full_messages, :unprocessable_entity)
  rescue ActiveRecord::RecordNotFound => e
    Result.failure(e.message, :not_found)
  end

  private

  attr_reader :payload

  def base_usuario_attributes
    payload.slice(:email, :password, :ativo)
  end

  def resolve_g_pessoa!(g_usuario)
    return find_or_build_g_pessoa_by_cpf(g_usuario) if cpf_value.present?
    return ensure_existing_g_pessoa!(GPessoa.find(payload[:g_pessoa_id])) if payload[:g_pessoa_id].present?

    build_g_pessoa(g_usuario)
  end

  def find_or_build_g_pessoa_by_cpf(g_usuario)
    person = GPessoa.find_by(cpf: cpf_value)
    return build_g_pessoa(g_usuario) unless person

    ensure_existing_g_pessoa!(person)
    update_g_pessoa_attributes(person, g_usuario)
  end

  def build_g_pessoa(g_usuario)
    person = GPessoa.new(g_pessoa_attributes)
    person.email = g_usuario.email if person.email.blank?
    person.ativo = g_usuario.ativo if person.respond_to?(:ativo=) && person.ativo.nil?
    person
  end

  def update_g_pessoa_attributes(person, g_usuario)
    person.assign_attributes(g_pessoa_attributes.except(:cpf))
    person.email = g_usuario.email if person.email.blank?
    person.ativo = g_usuario.ativo if person.respond_to?(:ativo=) && person.ativo.nil?
    person
  end

  def ensure_existing_g_pessoa!(person)
    return person unless person.g_usuario.present?

    raise ActiveRecord::RecordInvalid.new(person.tap { |record| record.errors.add(:base, "Pessoa informada já possui usuário vinculado") })
  end

  def g_pessoa_attributes
    attrs = payload[:g_pessoa].presence || legacy_g_pessoa_attributes
    attrs&.to_h&.symbolize_keys || {}
  end

  def legacy_g_pessoa_attributes
    payload.slice(:cpf, :descricao, :g_tipo_pessoa_id, :g_igreja_id, :email)
  end

  def cpf_value
    value = g_pessoa_attributes[:cpf]
    return if value.blank?

    GPessoa.normalize_cpf_value(value)
  end

  def sync_profile!(g_usuario)
    return unless payload[:g_perfil_id].present?

    GUsuarioPerfil.active.where(g_usuario_id: g_usuario.id).update_all(deleted_at: Time.current, updated_at: Time.current)
    perfil = GPerfil.active.find(payload[:g_perfil_id])
    record = GUsuarioPerfil.unscoped.find_or_initialize_by(g_usuario_id: g_usuario.id, g_perfil_id: perfil.id)
    record.deleted_at = nil
    record.save!
  end
end

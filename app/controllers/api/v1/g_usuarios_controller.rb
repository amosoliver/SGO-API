# frozen_string_literal: true

class Api::V1::GUsuariosController < ApplicationController
  before_action :set_g_usuario, only: %i[show update destroy]

  def index
    query = GUsuario.includes(:g_pessoa, :g_perfis).ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @g_usuario)
  end

  def create
    result = GUsuarioCreateService.new(g_usuario_payload).call
    return tratar_resposta(result) if result.failure?

    render_success(data: result.value, status: :created)
  end

  def update
    @g_usuario.assign_attributes(base_g_usuario_params)
    assign_person_attributes(@g_usuario)

    GUsuario.transaction do
      @g_usuario.save!
      sync_profile!(@g_usuario)
    end

    render_success(data: @g_usuario)
  rescue ActiveRecord::RecordInvalid => e
    if e.record == @g_usuario
      render_error(errors: @g_usuario.errors.full_messages)
    else
      render_error(errors: e.record.errors.full_messages)
    end
  end

  def destroy
    if @g_usuario.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @g_usuario.errors.full_messages)
    end
  end

  private

  def set_g_usuario
    @g_usuario = GUsuario.includes(:g_pessoa, :g_perfis).find(params[:id])
  end

  def g_usuario_payload
    params.require(:g_usuario).permit(
      :email,
      :password,
      :ativo,
      :g_pessoa_id,
      :cpf,
      :descricao,
      :g_perfil_id,
      :g_tipo_pessoa_id,
      :g_igreja_id,
      g_pessoa: %i[descricao email cpf ativo g_tipo_pessoa_id g_igreja_id]
    )
  end

  def base_g_usuario_params
    g_usuario_payload.slice(:email, :password, :ativo, :g_pessoa_id)
  end

  def assign_person_attributes(g_usuario)
    return if g_usuario_payload[:g_pessoa_id].present? && g_usuario_payload[:cpf].blank? && g_usuario_payload[:descricao].blank?

    g_usuario.g_pessoa ||= GPessoa.new
    g_usuario.g_pessoa.cpf = g_usuario_payload[:cpf] if g_usuario_payload[:cpf].present?
    g_usuario.g_pessoa.descricao = g_usuario_payload[:descricao] if g_usuario_payload[:descricao].present?
    g_usuario.g_pessoa.email = g_usuario.email if g_usuario.g_pessoa.email.blank?
    g_usuario.g_pessoa.ativo = g_usuario.ativo if g_usuario.g_pessoa.respond_to?(:ativo=)
  end

  def sync_profile!(g_usuario)
    return unless g_usuario_payload[:g_perfil_id].present?

    GUsuarioPerfil.active.where(g_usuario_id: g_usuario.id).update_all(deleted_at: Time.current, updated_at: Time.current)
    perfil = GPerfil.active.find(g_usuario_payload[:g_perfil_id])
    record = GUsuarioPerfil.unscoped.find_or_initialize_by(g_usuario_id: g_usuario.id, g_perfil_id: perfil.id)
    record.deleted_at = nil
    record.save!
  end
end

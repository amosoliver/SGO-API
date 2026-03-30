# frozen_string_literal: true

class Api::V1::GPerfisPermissoesController < ApplicationController
  before_action :set_g_perfil, only: %i[show update]
  before_action :set_g_perfil_permissao, only: :destroy

  def show
    render_success(data: @g_perfil.g_perfis_permissoes.includes(:g_permissao))
  end

  def create
    process_permissions(params.require(:g_perfil_permissao).permit(:g_perfil_id, g_permissoes_ids: []))
  end

  def update
    process_permissions(params.require(:g_perfil_permissao).permit(g_permissoes_ids: []), perfil: @g_perfil)
  end

  def destroy
    if @g_perfil_permissao.update(deleted_at: Time.current)
      render_success(message: "Vínculo removido com sucesso")
    else
      render_error(errors: @g_perfil_permissao.errors.full_messages)
    end
  end

  private

  def process_permissions(payload, perfil: nil)
    perfil ||= GPerfil.active.find(payload[:g_perfil_id])
    permission_ids = Array(payload[:g_permissoes_ids]).map(&:to_i).uniq

    GPerfilPermissao.transaction do
      perfil.g_perfis_permissoes.active.update_all(deleted_at: Time.current, updated_at: Time.current)

      permission_ids.each do |permission_id|
        record = GPerfilPermissao.unscoped.find_or_initialize_by(g_perfil_id: perfil.id, g_permissao_id: permission_id)
        record.deleted_at = nil
        record.save!
      end
    end

    render_success(data: perfil.g_perfis_permissoes.active.includes(:g_permissao), message: "Permissões atualizadas com sucesso")
  rescue ActiveRecord::RecordInvalid => e
    render_error(errors: e.record.errors.full_messages)
  end

  def set_g_perfil
    @g_perfil = GPerfil.active.find(params[:id])
  end

  def set_g_perfil_permissao
    @g_perfil_permissao = GPerfilPermissao.active.find(params[:id])
  end
end

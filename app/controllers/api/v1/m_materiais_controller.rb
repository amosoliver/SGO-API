# frozen_string_literal: true

class Api::V1::MMateriaisController < ApplicationController
  before_action :set_m_material, only: %i[show update destroy]

  def index
    query = m_materiais_scope.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @m_material)
  end

  def create
    @m_material = MMaterial.new(m_material_params)

    if @m_material.save
      render_success(data: @m_material, status: :created)
    else
      render_error(errors: @m_material.errors.full_messages)
    end
  end

  def update
    if @m_material.update(m_material_params)
      render_success(data: @m_material)
    else
      render_error(errors: @m_material.errors.full_messages)
    end
  end

  def destroy
    if @m_material.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @m_material.errors.full_messages)
    end
  end

  private

  def set_m_material
    @m_material = m_materiais_scope.find(params[:id])
  end

  def m_materiais_scope
    base_scope = MMaterial.includes(:m_musica, { g_instrumento_naipe: %i[g_instrumento g_naipe] }, arquivo_attachment: :blob)
    return base_scope unless current_user&.corista?

    base_scope.where(g_instrumento_naipe_id: current_user.associated_instrumento_naipe_ids)
  end

  def m_material_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = MMaterial.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:m_material).permit(permitted.map(&:to_sym))
  end
end

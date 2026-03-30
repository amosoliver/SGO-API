# frozen_string_literal: true

class Api::V1::MMateriaisController < ApplicationController
  before_action :set_m_material, only: %i[show update destroy]

  def index
    query = MMaterial.ransack(params[:q])
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
    @m_material = MMaterial.find(params[:id])
  end

  def m_material_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = MMaterial.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:m_material).permit(permitted.map(&:to_sym))
  end
end

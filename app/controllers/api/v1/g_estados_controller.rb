# frozen_string_literal: true

class Api::V1::GEstadosController < ApplicationController
  before_action :set_g_estado, only: %i[show update destroy]

  def index
    query = GEstado.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @g_estado)
  end

  def create
    @g_estado = GEstado.new(g_estado_params)

    if @g_estado.save
      render_success(data: @g_estado, status: :created)
    else
      render_error(errors: @g_estado.errors.full_messages)
    end
  end

  def update
    if @g_estado.update(g_estado_params)
      render_success(data: @g_estado)
    else
      render_error(errors: @g_estado.errors.full_messages)
    end
  end

  def destroy
    if @g_estado.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @g_estado.errors.full_messages)
    end
  end

  private

  def set_g_estado
    @g_estado = GEstado.find(params[:id])
  end

  def g_estado_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = GEstado.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:g_estado).permit(permitted.map(&:to_sym))
  end
end

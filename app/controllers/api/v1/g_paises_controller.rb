# frozen_string_literal: true

class Api::V1::GPaisesController < ApplicationController
  before_action :set_g_pais, only: %i[show update destroy]

  def index
    query = GPais.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @g_pais)
  end

  def create
    @g_pais = GPais.new(g_pais_params)

    if @g_pais.save
      render_success(data: @g_pais, status: :created)
    else
      render_error(errors: @g_pais.errors.full_messages)
    end
  end

  def update
    if @g_pais.update(g_pais_params)
      render_success(data: @g_pais)
    else
      render_error(errors: @g_pais.errors.full_messages)
    end
  end

  def destroy
    if @g_pais.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @g_pais.errors.full_messages)
    end
  end

  private

  def set_g_pais
    @g_pais = GPais.find(params[:id])
  end

  def g_pais_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = GPais.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:g_pais).permit(permitted.map(&:to_sym))
  end
end

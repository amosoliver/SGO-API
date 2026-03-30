# frozen_string_literal: true

class Api::V1::GInstrumentosController < ApplicationController
  before_action :set_g_instrumento, only: %i[show update destroy]

  def index
    query = GInstrumento.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @g_instrumento)
  end

  def create
    @g_instrumento = GInstrumento.new(g_instrumento_params)

    if @g_instrumento.save
      render_success(data: @g_instrumento, status: :created)
    else
      render_error(errors: @g_instrumento.errors.full_messages)
    end
  end

  def update
    if @g_instrumento.update(g_instrumento_params)
      render_success(data: @g_instrumento)
    else
      render_error(errors: @g_instrumento.errors.full_messages)
    end
  end

  def destroy
    if @g_instrumento.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @g_instrumento.errors.full_messages)
    end
  end

  private

  def set_g_instrumento
    @g_instrumento = GInstrumento.find(params[:id])
  end

  def g_instrumento_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = GInstrumento.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:g_instrumento).permit(permitted.map(&:to_sym))
  end
end

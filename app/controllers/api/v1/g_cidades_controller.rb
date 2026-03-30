# frozen_string_literal: true

class Api::V1::GCidadesController < ApplicationController
  before_action :set_g_cidade, only: %i[show update destroy]

  def index
    query = GCidade.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @g_cidade)
  end

  def create
    @g_cidade = GCidade.new(g_cidade_params)

    if @g_cidade.save
      render_success(data: @g_cidade, status: :created)
    else
      render_error(errors: @g_cidade.errors.full_messages)
    end
  end

  def update
    if @g_cidade.update(g_cidade_params)
      render_success(data: @g_cidade)
    else
      render_error(errors: @g_cidade.errors.full_messages)
    end
  end

  def destroy
    if @g_cidade.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @g_cidade.errors.full_messages)
    end
  end

  private

  def set_g_cidade
    @g_cidade = GCidade.find(params[:id])
  end

  def g_cidade_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = GCidade.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:g_cidade).permit(permitted.map(&:to_sym))
  end
end

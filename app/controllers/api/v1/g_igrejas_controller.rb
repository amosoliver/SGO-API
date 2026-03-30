# frozen_string_literal: true

class Api::V1::GIgrejasController < ApplicationController
  before_action :set_g_igreja, only: %i[show update destroy]

  def index
    query = GIgreja.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @g_igreja)
  end

  def create
    @g_igreja = GIgreja.new(g_igreja_params)

    if @g_igreja.save
      render_success(data: @g_igreja, status: :created)
    else
      render_error(errors: @g_igreja.errors.full_messages)
    end
  end

  def update
    if @g_igreja.update(g_igreja_params)
      render_success(data: @g_igreja)
    else
      render_error(errors: @g_igreja.errors.full_messages)
    end
  end

  def destroy
    if @g_igreja.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @g_igreja.errors.full_messages)
    end
  end

  private

  def set_g_igreja
    @g_igreja = GIgreja.find(params[:id])
  end

  def g_igreja_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = GIgreja.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:g_igreja).permit(permitted.map(&:to_sym))
  end
end

# frozen_string_literal: true

class Api::V1::GUsuariosController < ApplicationController
  before_action :set_g_usuario, only: %i[show update destroy]

  def index
    query = GUsuario.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @g_usuario)
  end

  def create
    @g_usuario = GUsuario.new(g_usuario_params)

    if @g_usuario.save
      render_success(data: @g_usuario, status: :created)
    else
      render_error(errors: @g_usuario.errors.full_messages)
    end
  end

  def update
    if @g_usuario.update(g_usuario_params)
      render_success(data: @g_usuario)
    else
      render_error(errors: @g_usuario.errors.full_messages)
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
    @g_usuario = GUsuario.find(params[:id])
  end

  def g_usuario_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = GUsuario.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:g_usuario).permit(permitted.map(&:to_sym))
  end
end

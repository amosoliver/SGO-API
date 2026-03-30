# frozen_string_literal: true

class Api::V1::GPerfisController < ApplicationController
  before_action :set_g_perfil, only: %i[show update destroy]

  def index
    query = GPerfil.active.includes(:users, :g_permissoes).order(:descricao).ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @g_perfil)
  end

  def create
    @g_perfil = GPerfil.new(g_perfil_params)

    if @g_perfil.save
      render_success(data: @g_perfil, status: :created)
    else
      render_error(errors: @g_perfil.errors.full_messages)
    end
  end

  def update
    if @g_perfil.update(g_perfil_params)
      render_success(data: @g_perfil)
    else
      render_error(errors: @g_perfil.errors.full_messages)
    end
  end

  def destroy
    if @g_perfil.update(deleted_at: Time.current)
      render_success(message: "Perfil removido com sucesso")
    else
      render_error(errors: @g_perfil.errors.full_messages)
    end
  end

  private

  def set_g_perfil
    @g_perfil = GPerfil.active.find(params[:id])
  end

  def g_perfil_params
    params.require(:g_perfil).permit(:descricao)
  end
end

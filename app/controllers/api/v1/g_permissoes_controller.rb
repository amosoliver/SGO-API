# frozen_string_literal: true

class Api::V1::GPermissoesController < ApplicationController
  before_action :set_g_permissao, only: %i[show update destroy]

  def index
    query = GPermissao.active.order(:controlador, :acao).ransack(params[:q])
    items = query.result

    render json: {
      items: ActiveModelSerializers::SerializableResource.new(items),
      total_count: items.size
    }
  end

  def show
    render_success(data: @g_permissao)
  end

  def create
    @g_permissao = GPermissao.new(g_permissao_params)

    if @g_permissao.save
      render_success(data: @g_permissao, status: :created)
    else
      render_error(errors: @g_permissao.errors.full_messages)
    end
  end

  def update
    if @g_permissao.update(g_permissao_params)
      render_success(data: @g_permissao)
    else
      render_error(errors: @g_permissao.errors.full_messages)
    end
  end

  def destroy
    if @g_permissao.update(deleted_at: Time.current)
      render_success(message: "Permissão removida com sucesso")
    else
      render_error(errors: @g_permissao.errors.full_messages)
    end
  end

  private

  def set_g_permissao
    @g_permissao = GPermissao.active.find(params[:id])
  end

  def g_permissao_params
    params.require(:g_permissao).permit(:controlador, :acao, :nome_controlador, :nome_acao, :admin)
  end
end

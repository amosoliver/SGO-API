# frozen_string_literal: true

class Api::V1::GPessoaNaipesController < ApplicationController
  before_action :set_g_pessoa_naipe, only: %i[show update destroy]

  def index
    query = GPessoaNaipe.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @g_pessoa_naipe)
  end

  def create
    @g_pessoa_naipe = GPessoaNaipe.new(g_pessoa_naipe_params)

    if @g_pessoa_naipe.save
      render_success(data: @g_pessoa_naipe, status: :created)
    else
      render_error(errors: @g_pessoa_naipe.errors.full_messages)
    end
  end

  def update
    if @g_pessoa_naipe.update(g_pessoa_naipe_params)
      render_success(data: @g_pessoa_naipe)
    else
      render_error(errors: @g_pessoa_naipe.errors.full_messages)
    end
  end

  def destroy
    if @g_pessoa_naipe.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @g_pessoa_naipe.errors.full_messages)
    end
  end

  private

  def set_g_pessoa_naipe
    @g_pessoa_naipe = GPessoaNaipe.find(params[:id])
  end

  def g_pessoa_naipe_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = GPessoaNaipe.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:g_pessoa_naipe).permit(permitted.map(&:to_sym))
  end
end

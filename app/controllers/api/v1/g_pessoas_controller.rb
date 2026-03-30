# frozen_string_literal: true

class Api::V1::GPessoasController < ApplicationController
  before_action :set_g_pessoa, only: %i[show update destroy]

  def index
    query = GPessoa.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @g_pessoa)
  end

  def create
    @g_pessoa = GPessoa.new(g_pessoa_params)

    if @g_pessoa.save
      render_success(data: @g_pessoa, status: :created)
    else
      render_error(errors: @g_pessoa.errors.full_messages)
    end
  end

  def update
    if @g_pessoa.update(g_pessoa_params)
      render_success(data: @g_pessoa)
    else
      render_error(errors: @g_pessoa.errors.full_messages)
    end
  end

  def destroy
    if @g_pessoa.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @g_pessoa.errors.full_messages)
    end
  end

  private

  def set_g_pessoa
    @g_pessoa = GPessoa.find(params[:id])
  end

  def g_pessoa_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = GPessoa.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:g_pessoa).permit(permitted.map(&:to_sym))
  end
end

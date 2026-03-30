# frozen_string_literal: true

class Api::V1::GTiposPessoaController < ApplicationController
  before_action :set_g_tipo_pessoa, only: %i[show update destroy]

  def index
    query = GTipoPessoa.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @g_tipo_pessoa)
  end

  def create
    @g_tipo_pessoa = GTipoPessoa.new(g_tipo_pessoa_params)

    if @g_tipo_pessoa.save
      render_success(data: @g_tipo_pessoa, status: :created)
    else
      render_error(errors: @g_tipo_pessoa.errors.full_messages)
    end
  end

  def update
    if @g_tipo_pessoa.update(g_tipo_pessoa_params)
      render_success(data: @g_tipo_pessoa)
    else
      render_error(errors: @g_tipo_pessoa.errors.full_messages)
    end
  end

  def destroy
    if @g_tipo_pessoa.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @g_tipo_pessoa.errors.full_messages)
    end
  end

  private

  def set_g_tipo_pessoa
    @g_tipo_pessoa = GTipoPessoa.find(params[:id])
  end

  def g_tipo_pessoa_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = GTipoPessoa.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:g_tipo_pessoa).permit(permitted.map(&:to_sym))
  end
end

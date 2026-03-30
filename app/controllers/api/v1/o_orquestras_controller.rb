# frozen_string_literal: true

class Api::V1::OOrquestrasController < ApplicationController
  before_action :set_o_orquestra, only: %i[show update destroy]

  def index
    query = OOrquestra.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @o_orquestra)
  end

  def create
    @o_orquestra = OOrquestra.new(o_orquestra_params)

    if @o_orquestra.save
      render_success(data: @o_orquestra, status: :created)
    else
      render_error(errors: @o_orquestra.errors.full_messages)
    end
  end

  def update
    if @o_orquestra.update(o_orquestra_params)
      render_success(data: @o_orquestra)
    else
      render_error(errors: @o_orquestra.errors.full_messages)
    end
  end

  def destroy
    if @o_orquestra.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @o_orquestra.errors.full_messages)
    end
  end

  private

  def set_o_orquestra
    @o_orquestra = OOrquestra.find(params[:id])
  end

  def o_orquestra_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = OOrquestra.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:o_orquestra).permit(permitted.map(&:to_sym))
  end
end

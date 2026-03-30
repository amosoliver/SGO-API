# frozen_string_literal: true

class Api::V1::CCoraisController < ApplicationController
  before_action :set_c_coral, only: %i[show update destroy]

  def index
    query = CCoral.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @c_coral)
  end

  def create
    @c_coral = CCoral.new(c_coral_params)

    if @c_coral.save
      render_success(data: @c_coral, status: :created)
    else
      render_error(errors: @c_coral.errors.full_messages)
    end
  end

  def update
    if @c_coral.update(c_coral_params)
      render_success(data: @c_coral)
    else
      render_error(errors: @c_coral.errors.full_messages)
    end
  end

  def destroy
    if @c_coral.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @c_coral.errors.full_messages)
    end
  end

  private

  def set_c_coral
    @c_coral = CCoral.find(params[:id])
  end

  def c_coral_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = CCoral.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:c_coral).permit(permitted.map(&:to_sym))
  end
end

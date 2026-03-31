# frozen_string_literal: true

class Api::V1::GNaipesController < ApplicationController
  before_action :set_g_naipe, only: %i[show update destroy]

  def index
    query = g_naipes_scope.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @g_naipe)
  end

  def create
    @g_naipe = GNaipe.new(g_naipe_params)

    if @g_naipe.save
      render_success(data: @g_naipe, status: :created)
    else
      render_error(errors: @g_naipe.errors.full_messages)
    end
  end

  def update
    if @g_naipe.update(g_naipe_params)
      render_success(data: @g_naipe)
    else
      render_error(errors: @g_naipe.errors.full_messages)
    end
  end

  def destroy
    if @g_naipe.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @g_naipe.errors.full_messages)
    end
  end

  private

  def set_g_naipe
    @g_naipe = g_naipes_scope.find(params[:id])
  end

  def g_naipes_scope
    return GNaipe.all unless current_user&.corista?

    GNaipe.where(id: current_user.associated_naipe_ids)
  end

  def g_naipe_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = GNaipe.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:g_naipe).permit(permitted.map(&:to_sym))
  end
end

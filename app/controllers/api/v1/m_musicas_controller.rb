# frozen_string_literal: true

class Api::V1::MMusicasController < ApplicationController
  before_action :set_m_musica, only: %i[show update destroy]

  def index
    query = MMusica.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @m_musica)
  end

  def create
    @m_musica = MMusica.new(m_musica_params)

    if @m_musica.save
      render_success(data: @m_musica, status: :created)
    else
      render_error(errors: @m_musica.errors.full_messages)
    end
  end

  def update
    if @m_musica.update(m_musica_params)
      render_success(data: @m_musica)
    else
      render_error(errors: @m_musica.errors.full_messages)
    end
  end

  def destroy
    if @m_musica.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @m_musica.errors.full_messages)
    end
  end

  private

  def set_m_musica
    @m_musica = MMusica.find(params[:id])
  end

  def m_musica_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = MMusica.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:m_musica).permit(permitted.map(&:to_sym))
  end
end

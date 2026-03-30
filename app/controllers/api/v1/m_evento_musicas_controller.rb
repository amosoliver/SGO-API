# frozen_string_literal: true

class Api::V1::MEventoMusicasController < ApplicationController
  before_action :set_m_evento_musica, only: %i[show update destroy]

  def index
    query = MEventoMusica.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @m_evento_musica)
  end

  def create
    @m_evento_musica = MEventoMusica.new(m_evento_musica_params)

    if @m_evento_musica.save
      render_success(data: @m_evento_musica, status: :created)
    else
      render_error(errors: @m_evento_musica.errors.full_messages)
    end
  end

  def update
    if @m_evento_musica.update(m_evento_musica_params)
      render_success(data: @m_evento_musica)
    else
      render_error(errors: @m_evento_musica.errors.full_messages)
    end
  end

  def destroy
    if @m_evento_musica.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @m_evento_musica.errors.full_messages)
    end
  end

  private

  def set_m_evento_musica
    @m_evento_musica = MEventoMusica.find(params[:id])
  end

  def m_evento_musica_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = MEventoMusica.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:m_evento_musica).permit(permitted.map(&:to_sym))
  end
end

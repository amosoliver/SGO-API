# frozen_string_literal: true

class Api::V1::MEventosController < ApplicationController
  before_action :set_m_evento, only: %i[show update destroy]

  def index
    query = MEvento.ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @m_evento)
  end

  def create
    @m_evento = MEvento.new(m_evento_params)

    if @m_evento.save
      render_success(data: evento_create_payload(@m_evento), status: :created)
    else
      render_error(errors: @m_evento.errors.full_messages)
    end
  end

  def update
    if @m_evento.update(m_evento_params)
      render_success(data: @m_evento)
    else
      render_error(errors: @m_evento.errors.full_messages)
    end
  end

  def destroy
    if @m_evento.destroy
      render_success(message: "Registro excluído com sucesso!")
    else
      render_error(errors: @m_evento.errors.full_messages)
    end
  end

  private

  def set_m_evento
    @m_evento = MEvento.find(params[:id])
  end

  def m_evento_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = MEvento.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:m_evento).permit(permitted.map(&:to_sym))
  end

  def evento_create_payload(evento)
    {
      evento: serialize_data(evento).as_json,
      gerenciamento_musicas: {
        m_evento_id: evento.id,
        index_path: api_v1_m_evento_m_evento_musicas_path(evento),
        create_path: api_v1_m_evento_m_evento_musicas_path(evento)
      }
    }
  end
end

# frozen_string_literal: true

class Api::V1::MMusicasController < ApplicationController
  before_action :set_m_musica, only: %i[show update destroy]
  before_action :set_m_musica, only: :upload_materiais

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

  def upload_materiais
    result = MateriaisLoteUploadService.new(
      m_musica: @m_musica,
      materiais: materiais_upload_params[:materiais],
      url_options: upload_url_options
    ).call

    return tratar_resposta(result) if result.failure?

    render_success(data: result.value, message: result.message, status: :created)
  end

  private

  def set_m_musica
    @m_musica = MMusica.includes(m_materiais: [{ g_instrumento_naipe: %i[g_instrumento g_naipe] }, { arquivo_attachment: :blob }]).find(params[:id])
  end

  def m_musica_params
    unpermitted = %w[id created_by updated_by deleted_at created_at updated_at]
    permitted = MMusica.column_names.reject { |col| unpermitted.include?(col) }
    params.require(:m_musica).permit(*(permitted.map(&:to_sym) + %i[duracao_minutos duracao_segundos]))
  end

  def materiais_upload_params
    params.permit(materiais: %i[descricao tipo g_instrumento_naipe_id arquivo])
  end

  def upload_url_options
    base_options = Rails.application.config.action_mailer.default_url_options || {}
    if request.present?
      { host: request.host, port: request.optional_port, protocol: request.protocol.delete_suffix("://") }
    else
      { host: base_options[:host], port: base_options[:port], protocol: "http" }
    end
  end
end

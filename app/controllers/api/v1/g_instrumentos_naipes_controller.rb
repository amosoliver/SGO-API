# frozen_string_literal: true

class Api::V1::GInstrumentosNaipesController < ApplicationController
  before_action :set_g_instrumento_naipe, only: %i[show update destroy]

  def index
    query = GInstrumentoNaipe.active.includes(:g_instrumento, :g_naipe).order(:ordem, :id).ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @g_instrumento_naipe)
  end

  def create
    @g_instrumento_naipe = GInstrumentoNaipe.new(g_instrumento_naipe_params)

    if @g_instrumento_naipe.save
      render_success(data: @g_instrumento_naipe, status: :created)
    else
      render_error(errors: @g_instrumento_naipe.errors.full_messages)
    end
  end

  def update
    if @g_instrumento_naipe.update(g_instrumento_naipe_params)
      render_success(data: @g_instrumento_naipe)
    else
      render_error(errors: @g_instrumento_naipe.errors.full_messages)
    end
  end

  def destroy
    if @g_instrumento_naipe.update(deleted_at: Time.current)
      render_success(message: "Registro removido com sucesso.")
    else
      render_error(errors: @g_instrumento_naipe.errors.full_messages)
    end
  end

  private

  def set_g_instrumento_naipe
    @g_instrumento_naipe = GInstrumentoNaipe.active.find(params[:id])
  end

  def g_instrumento_naipe_params
    params.require(:g_instrumento_naipe).permit(:g_instrumento_id, :g_naipe_id, :ordem)
  end
end

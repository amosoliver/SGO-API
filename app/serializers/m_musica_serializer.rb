# frozen_string_literal: true

class MMusicaSerializer < ActiveModel::Serializer
  attributes :id, :descricao, :tonalidade, :bpm, :duracao, :duracao_minutos, :duracao_segundos
  has_many :m_materiais

  def duracao
    object.duracao_formatada
  end

  def duracao_minutos
    return if object.duracao.blank?

    object.duracao.hour * 60 + object.duracao.min
  end

  def duracao_segundos
    return if object.duracao.blank?

    object.duracao.sec
  end

  def m_materiais
    materiais = object.m_materiais.order(:id)
    return materiais unless scope&.corista?

    materiais.where(g_instrumento_naipe_id: scope.associated_instrumento_naipe_ids)
  end
end

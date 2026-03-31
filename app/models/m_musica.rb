# frozen_string_literal: true

# Associações:


# Atributos:
# string - descricao
# string - tonalidade
# integer - bpm
# time - duracao

class MMusica < ApplicationRecord
  attr_accessor :duracao_minutos, :duracao_segundos

  has_many :m_materiais, dependent: :destroy

  before_validation :normalize_duracao

  def duracao_formatada
    return if duracao.blank?

    format("%02d:%02d", duracao.hour * 60 + duracao.min, duracao.sec)
  end

  private

  def normalize_duracao
    if duracao_minutos.present? || duracao_segundos.present?
      self.duracao = build_duration_time(duracao_minutos.to_i, duracao_segundos.to_i)
      return
    end

    return unless duracao.is_a?(String)

    value = duracao.strip
    if value.match?(/\A\d+\z/)
      total_seconds = value.to_i
      return self.duracao = build_duration_time(total_seconds / 60, total_seconds % 60)
    end

    match = value.match(/\A(\d{1,3}):(\d{1,2})\z/)
    return if match.blank?

    self.duracao = build_duration_time(match[1].to_i, match[2].to_i)
  end

  def build_duration_time(minutes, seconds)
    Time.zone.local(2000, 1, 1, 0, minutes, seconds)
  end
end

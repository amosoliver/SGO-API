# frozen_string_literal: true

# Associações:
# m_musica
# g_instrumento_naipe


# Atributos:
# string - tipo
# string - descricao
# string - arquivo_url

class MMaterial < ApplicationRecord
  belongs_to :m_musica
  belongs_to :g_instrumento_naipe
  has_one :g_instrumento, through: :g_instrumento_naipe
  has_one :g_naipe, through: :g_instrumento_naipe
  has_one_attached :arquivo

  delegate :g_instrumento_id, :g_naipe_id, to: :g_instrumento_naipe, allow_nil: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[arquivo_url created_at created_by deleted_at descricao g_instrumento_naipe_id id m_musica_id tipo updated_at updated_by]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[g_instrumento g_instrumento_naipe g_naipe m_musica]
  end

  def sync_arquivo_url!(url_options)
    return unless arquivo.attached?

    update_column(
      :arquivo_url,
      Rails.application.routes.url_helpers.rails_blob_url(arquivo, **url_options)
    )
  end
end

# frozen_string_literal: true

class MMaterialSerializer < ActiveModel::Serializer
  attributes :id, :tipo, :descricao, :arquivo_url
  belongs_to :m_musica
  belongs_to :g_instrumento
  belongs_to :g_naipe
end

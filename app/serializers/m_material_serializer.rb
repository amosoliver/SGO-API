# frozen_string_literal: true

class MMaterialSerializer < ActiveModel::Serializer
  attributes :id, :tipo, :descricao, :arquivo_url, :arquivo_nome, :arquivo_content_type,
             :m_musica_id, :g_instrumento_naipe_id, :g_instrumento_id, :g_naipe_id,
             :g_instrumento_descricao, :g_naipe_descricao
  belongs_to :m_musica
  belongs_to :g_instrumento_naipe

  def g_instrumento_id
    object.g_instrumento_naipe&.g_instrumento_id
  end

  def g_naipe_id
    object.g_instrumento_naipe&.g_naipe_id
  end

  def g_instrumento_descricao
    object.g_instrumento&.descricao
  end

  def g_naipe_descricao
    object.g_naipe&.descricao
  end

  def arquivo_nome
    object.arquivo.filename.to_s if object.arquivo.attached?
  end

  def arquivo_content_type
    object.arquivo.content_type if object.arquivo.attached?
  end
end

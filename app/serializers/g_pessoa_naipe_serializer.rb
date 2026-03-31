# frozen_string_literal: true

class GPessoaNaipeSerializer < ActiveModel::Serializer
  attributes :id, :principal, :posicao, :g_pessoa_id, :g_instrumento_id, :g_naipe_id
  belongs_to :g_pessoa
  belongs_to :g_instrumento
  belongs_to :g_naipe
end

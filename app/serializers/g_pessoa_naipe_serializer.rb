# frozen_string_literal: true

class GPessoaNaipeSerializer < ActiveModel::Serializer
  attributes :id, :principal, :posicao
  belongs_to :g_pessoa
  belongs_to :g_instrumento
  belongs_to :g_naipe
end

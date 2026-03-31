# frozen_string_literal: true

class GInstrumentoNaipeSerializer < ActiveModel::Serializer
  attributes :id, :g_instrumento_id, :g_naipe_id, :ordem

  belongs_to :g_instrumento
  belongs_to :g_naipe
end

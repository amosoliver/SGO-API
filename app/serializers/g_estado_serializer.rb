# frozen_string_literal: true

class GEstadoSerializer < ActiveModel::Serializer
  attributes :id, :descricao, :sigla
  belongs_to :g_pais
end

# frozen_string_literal: true

class GEstadoSerializer < ActiveModel::Serializer
  attributes :id, :descricao, :sigla, :g_pais_id
  belongs_to :g_pais
end

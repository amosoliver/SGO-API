# frozen_string_literal: true

class MMusicaSerializer < ActiveModel::Serializer
  attributes :id, :descricao, :tonalidade, :bpm, :duracao
end

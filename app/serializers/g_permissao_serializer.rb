# frozen_string_literal: true

class GPermissaoSerializer < ActiveModel::Serializer
  attributes :id, :controlador, :acao, :nome_controlador, :nome_acao, :admin
end

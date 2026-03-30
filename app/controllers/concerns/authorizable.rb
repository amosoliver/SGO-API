# frozen_string_literal: true

module Authorizable
  extend ActiveSupport::Concern

  included do
    before_action :validar_permissoes
  end

  private

  def validar_permissoes
    user = RequestStore.store[:current_user]
    return if user.blank? || user.admin?

    decoded_token = RequestStore.store[:decoded_token]
    return render_error(message: "Token inválido ou expirado", status: :unauthorized) if decoded_token.blank?

    if user.g_perfil_id.blank?
      return render_error(
        message: "Usuário sem perfil de acesso atribuído. Contate o administrador.",
        status: :forbidden
      )
    end

    result = ValidarAcessoService.new(
      user: user,
      controller: controller_name,
      action: action_name,
      uuid: decoded_token["jti"]
    ).call

    render_error(message: result.message, status: :forbidden) if result.failure?
  end
end

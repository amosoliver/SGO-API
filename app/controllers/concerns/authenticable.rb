# frozen_string_literal: true

module Authenticable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  def current_user
    RequestStore.store[:current_user]
  end

  private

  def authenticate_user!
    token = extract_token_from_header
    return render_error(message: "Acesso não autorizado. Faça o login.", status: :unauthorized) if token.blank?

    decoded_token = TokenService.decode_access_token(token)
    return render_error(message: "Token inválido ou expirado.", status: :unauthorized) if decoded_token.blank?

    user = User.find_by(id: decoded_token["user_id"], deleted_at: nil)
    return render_error(message: "Token inválido ou expirado.", status: :unauthorized) if user.blank?

    RequestStore.store[:current_user] = user
    RequestStore.store[:decoded_token] = decoded_token
  end

  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    return if auth_header.blank? || !auth_header.start_with?("Bearer ")

    auth_header.split.last
  end
end

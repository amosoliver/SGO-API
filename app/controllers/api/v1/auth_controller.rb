# frozen_string_literal: true

class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[login refresh_token primeiro_acesso]
  skip_before_action :validar_permissoes, only: %i[login refresh_token primeiro_acesso]

  # @swagger_summary_login: Login com CPF
  # @swagger_description_login: Autentica o usuario usando CPF e senha. O campo login tambem aceita CPF para compatibilidade com o frontend.
  # @swagger_params_login: cpf, login, password
  # @swagger_response_login: access_token, refresh_token, user
  def login
    user = find_user_by_credential

    if user&.valid_password?(login_params[:password]) && !user.deleted_at?
      if user.primeiro_acesso?
        return render json: {
          error: "Primeiro acesso requerido",
          primeiro_acesso: true,
          token: user.token_primeiro_acesso
        }, status: :unauthorized
      end

      token_result = TokenService.generate_access_token(user)
      return tratar_resposta(token_result) if token_result.failure?

      render_success(
        data: {
          user: user,
          access_token: token_result.value,
          refresh_token: TokenService.generate_refresh_token(user)
        },
        message: "Login bem-sucedido"
      )
    else
      render_error(message: "Credenciais inválidas", status: :unauthorized)
    end
  end

  def me
    render_success(data: current_user)
  end

  def logout
    TokenService.invalidate_old_refresh_token(current_user)
    render_success(message: "Logout realizado com sucesso")
  end

  def refresh_token
    refresh_token = request.headers["Refresh-Token"] || params[:refresh_token]
    user = refresh_token.present? ? GUsuario.find_by(refresh_token: refresh_token, deleted_at: nil) : nil

    unless user && TokenService.valid_refresh_token?(user, refresh_token)
      return render_error(message: "Sessão inválida. Faça login novamente.", status: :unauthorized)
    end

    token_result = TokenService.refresh_access_token(user)
    return tratar_resposta(token_result) if token_result.failure?

    render_success(
      data: {
        access_token: token_result.value,
        refresh_token: TokenService.generate_refresh_token(user)
      },
      message: "Token de acesso atualizado"
    )
  end

  def update_password
    unless current_user.valid_password?(update_password_params[:current_password])
      return render_error(message: "Senha atual inválida.", status: :unauthorized)
    end

    if current_user.update(
      password: update_password_params[:new_password],
      password_confirmation: update_password_params[:new_password_confirmation],
      primeiro_acesso: false,
      token_primeiro_acesso: nil
    )
      token_result = TokenService.refresh_access_token(current_user)
      return tratar_resposta(token_result) if token_result.failure?

      render_success(
        data: {
          access_token: token_result.value,
          refresh_token: TokenService.generate_refresh_token(current_user)
        },
        message: "Senha atualizada com sucesso."
      )
    else
      render_error(errors: current_user.errors.full_messages)
    end
  end

  def primeiro_acesso
    user = GUsuario.find_by(token_primeiro_acesso: primeiro_acesso_params[:token], primeiro_acesso: true, deleted_at: nil)
    return render_error(message: "Token inválido ou usuário não encontrado.", status: :not_found) if user.blank?

    if user.update(
      password: primeiro_acesso_params[:password],
      password_confirmation: primeiro_acesso_params[:password_confirmation],
      primeiro_acesso: false,
      token_primeiro_acesso: nil
    )
      render_success(message: "Senha definida com sucesso. Faça login para continuar.")
    else
      render_error(errors: user.errors.full_messages)
    end
  end

  def get_permissions
    permissions = TokenService.get_permissoes_from_redis(params[:jti])
    return render_error(message: "Nenhuma permissão foi encontrada com esse id", status: :unprocessable_entity) if permissions.blank?

    render_success(data: { permissions: permissions })
  end

  def sincronizar_permissoes
    PermissionSyncService.new.call
    ProfilePermissionSyncService.new.call(assign_admin_to: current_user)

    render_success(message: "Atualização e sincronização de permissões concluída.")
  rescue StandardError => e
    render_error(message: "Falha na execução", errors: e.message, status: :internal_server_error)
  end

  private

  def login_params
    params.permit(:cpf, :login, :email, :password)
  end

  def update_password_params
    params.permit(:current_password, :new_password, :new_password_confirmation)
  end

  def primeiro_acesso_params
    params.permit(:token, :password, :password_confirmation)
  end

  def find_user_by_credential
    credential = login_params[:cpf].presence || login_params[:login].presence || login_params[:email].presence
    GUsuario.find_active_by_login(credential)
  end
end

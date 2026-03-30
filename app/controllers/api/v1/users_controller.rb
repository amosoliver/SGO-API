# frozen_string_literal: true

class Api::V1::UsersController < ApplicationController
  before_action :set_user, only: %i[show update destroy]

  def index
    query = User.active.includes(:g_perfil).order(:nome).ransack(params[:q])
    render ResponseService.pagy_index(query.result, params, self)
  end

  def show
    render_success(data: @user)
  end

  def create
    @user = User.new(user_params)
    apply_initial_password(@user)

    if @user.save
      render_success(
        data: {
          user: @user,
          token_primeiro_acesso: @user.token_primeiro_acesso
        },
        message: "Usuário criado com sucesso",
        status: :created
      )
    else
      render_error(errors: @user.errors.full_messages)
    end
  end

  def update
    attrs = user_params.to_h
    if attrs["password"].blank?
      attrs.except!("password", "password_confirmation")
    end

    if @user.update(attrs)
      render_success(data: @user, message: "Usuário atualizado com sucesso")
    else
      render_error(errors: @user.errors.full_messages)
    end
  end

  def destroy
    if @user.update(deleted_at: Time.current)
      render_success(message: "Usuário inativado com sucesso")
    else
      render_error(errors: @user.errors.full_messages)
    end
  end

  private

  def set_user
    @user = User.active.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :nome,
      :email,
      :cpf,
      :admin,
      :g_perfil_id,
      :password,
      :password_confirmation,
      :primeiro_acesso
    )
  end

  def apply_initial_password(user)
    if user.password.blank?
      temporary_password = SecureRandom.base58(10)
      user.password = temporary_password
      user.password_confirmation = temporary_password
      user.primeiro_acesso = true
      user.token_primeiro_acesso ||= SecureRandom.hex(16)
    elsif user.primeiro_acesso?
      user.token_primeiro_acesso ||= SecureRandom.hex(16)
    end
  end
end

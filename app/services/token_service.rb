# frozen_string_literal: true

class TokenService
  def self.generate_access_token(user)
    permissions_hash = build_permissoes_usuario(user)
    jti = SecureRandom.uuid

    payload = {
      user_id: user.id,
      user_nome: user.nome,
      user_admin: user.admin,
      email: user.email,
      g_perfil_id: user.g_perfil_id,
      administrador: user.admin?,
      jti: jti,
      exp: 24.hours.from_now.to_i
    }

    save_permissoes_redis(jti, permissions_hash) if permissions_hash.present?

    token = JWT.encode(payload, secret_key, "HS256")
    Result.success(token, 200, "Token gerado com sucesso")
  rescue StandardError => e
    Result.failure(e.message, 500, "Erro ao gerar token")
  end

  def self.generate_refresh_token(user)
    refresh_token = SecureRandom.hex(64)
    user.update!(refresh_token: refresh_token)
    refresh_token
  end

  def self.decode_access_token(token)
    decoded = JWT.decode(token, secret_key, true, algorithm: "HS256")
    decoded.first
  rescue JWT::DecodeError
    nil
  end

  def self.invalidate_old_refresh_token(user)
    user.update(refresh_token: nil)
  end

  def self.valid_refresh_token?(user, refresh_token)
    user.refresh_token == refresh_token
  end

  def self.refresh_access_token(user)
    generate_access_token(user)
  end

  def self.build_permissoes_usuario(user)
    scope = user.admin? ? GPermissao.active : user.g_permissoes.active.nao_admin

    scope.distinct.each_with_object({}) do |permissao, result|
      controlador = permissao.controlador
      result[controlador] ||= { actions: [] }
      result[controlador][:actions] << permissao.acao
    end
  end

  def self.get_permissoes_from_redis(jti)
    return if jti.blank?

    RedisService.fetch(jti)
  rescue StandardError => e
    Rails.logger.warn("Erro ao buscar permissões no redis: #{e.message}")
    nil
  end

  def self.save_permissoes_redis(jti, permissoes)
    RedisService.save!(jti, permissoes, 24.hours.to_i)
  rescue StandardError => e
    Rails.logger.warn("Não foi possível salvar permissões no redis: #{e.message}")
  end

  def self.secret_key
    ENV["JWT_SECRET_KEY"] || Rails.application.secret_key_base
  end

  private_class_method :save_permissoes_redis, :secret_key
end

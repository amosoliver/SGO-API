# frozen_string_literal: true

class ValidarAcessoService
  def initialize(user:, controller:, action:, uuid:)
    @user = user
    @controller = controller
    @action = action
    @uuid = uuid
  end

  def call
    return Result.success(true) if @user.admin?
    return Result.success(true) if @action == "me"

    permitido = redis_online? ? verificar_permissao_redis : verificar_permissao_banco
    return Result.success(true) if permitido

    Result.failure("Usuário sem permissão para essa ação", 403, "Acesso negado")
  end

  private

  def verificar_permissao_redis
    permissoes = RedisService.fetch(@uuid)
    return false if permissoes.blank?

    nome_chave = normalizar_nome_controlador
    permissoes_controlador = permissoes[nome_chave] || permissoes[nome_chave.to_sym]
    Array(permissoes_controlador&.fetch("actions", permissoes_controlador&.fetch(:actions, []))).include?(@action)
  end

  def verificar_permissao_banco
    GPermissao.active
              .joins(:g_perfis_permissoes)
              .where(controlador: normalizar_nome_controlador, acao: @action, g_perfis_permissoes: { g_perfil_id: @user.g_perfil_id, deleted_at: nil })
              .exists?
  end

  def redis_online?
    RedisService.ping == "PONG"
  rescue StandardError
    false
  end

  def normalizar_nome_controlador
    @controller.end_with?("_controller") ? @controller : "#{@controller}_controller"
  end
end

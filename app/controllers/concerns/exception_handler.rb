# frozen_string_literal: true

module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_parse_error
    rescue_from ActiveRecord::InvalidForeignKey, with: :handle_foreign_key_error
    rescue_from ActiveRecord::DeleteRestrictionError, with: :handle_delete_restriction_error
    rescue_from StandardError, with: :internal_server_error
  end

  private

  def handle_foreign_key_error(exception)
    render_error(
      message: "Não é possível excluir este registro porque ele está sendo usado em outra tabela.",
      errors: exception.message,
      status: :unprocessable_entity
    )
  end

  def handle_delete_restriction_error(exception)
    render_error(
      message: "Não é possível excluir este registro porque existem registros dependentes associados.",
      errors: exception.message,
      status: :unprocessable_entity
    )
  end

  def internal_server_error(exception)
    Rails.logger.error("Internal Error: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n")) if exception.backtrace.present?

    render_error(
      message: "Falha de processamento interno do servidor",
      errors: exception.message,
      status: :internal_server_error
    )
  end

  def record_not_found(exception)
    render_error(
      message: "Registro não encontrado",
      errors: exception.message,
      status: :not_found
    )
  end

  def handle_parse_error(exception)
    render_error(
      message: "JSON inválido, revise a requisição.",
      errors: exception.message,
      status: :bad_request
    )
  end
end

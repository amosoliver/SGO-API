# frozen_string_literal: true

module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
    rescue_from ActiveRecord::RecordNotUnique, with: :handle_record_not_unique
    rescue_from ActiveRecord::NotNullViolation, with: :handle_not_null_violation
    rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_parse_error
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
    rescue_from ActiveRecord::InvalidForeignKey, with: :handle_foreign_key_error
    rescue_from ActiveRecord::DeleteRestrictionError, with: :handle_delete_restriction_error
    rescue_from ActiveRecord::StatementInvalid, with: :handle_statement_invalid
    rescue_from StandardError, with: :internal_server_error
  end

  private

  def handle_record_invalid(exception)
    record = exception.record
    errors = record&.errors&.full_messages.presence || [translate_database_message(exception.message)]

    render_error(
      message: "Não foi possível salvar os dados informados.",
      errors: errors,
      status: :unprocessable_entity
    )
  end

  def handle_record_not_unique(exception)
    render_error(
      message: "Já existe um registro com os dados informados.",
      errors: [translate_database_message(exception.message)],
      status: :unprocessable_entity
    )
  end

  def handle_not_null_violation(exception)
    render_error(
      message: "Existem campos obrigatórios que não foram preenchidos.",
      errors: [translate_database_message(exception.message)],
      status: :unprocessable_entity
    )
  end

  def handle_foreign_key_error(exception)
    render_error(
      message: foreign_key_message(exception),
      errors: [translate_database_message(exception.message)],
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
      message: "Ocorreu um erro interno ao processar a requisição.",
      errors: [translate_database_message(exception.message)],
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

  def handle_parameter_missing(exception)
    render_error(
      message: "Parâmetro obrigatório não informado na requisição.",
      errors: ["O parâmetro '#{exception.param}' é obrigatório."],
      status: :bad_request
    )
  end

  def handle_parse_error(exception)
    render_error(
      message: "JSON inválido, revise a requisição.",
      errors: [translate_database_message(exception.message)],
      status: :bad_request
    )
  end

  def handle_statement_invalid(exception)
    cause = exception.cause

    case cause
    when PG::ForeignKeyViolation
      handle_foreign_key_error(exception)
    when PG::NotNullViolation
      handle_not_null_violation(exception)
    when PG::UniqueViolation
      handle_record_not_unique(exception)
    else
      render_error(
        message: "Não foi possível concluir a operação no banco de dados.",
        errors: [translate_database_message(exception.message)],
        status: :unprocessable_entity
      )
    end
  end

  def foreign_key_message(exception)
    if exception.message.match?(/delete|update/i)
      "Não é possível excluir ou alterar este registro porque ele está vinculado a outros dados."
    else
      "Não foi possível salvar porque um dos relacionamentos informados é inválido."
    end
  end

  def translate_database_message(message)
    translated = message.to_s.dup

    translated.gsub!(/PG::\w+:\s*/, "")
    translated.gsub!(/ERROR:\s*/, "")
    translated.gsub!(/DETAIL:\s*/, "")

    translations.each do |pattern, replacement|
      translated.gsub!(pattern, replacement)
    end

    translated.strip.presence || "Erro de banco de dados."
  end

  def translations
    {
      /violates foreign key constraint/i => "viola uma restrição de chave estrangeira",
      /violates unique constraint/i => "viola uma restrição de unicidade",
      /null value in column "(.*?)" violates not-null constraint/i => 'o campo "\1" é obrigatório',
      /duplicate key value/i => "já existe um registro com esse valor",
      /is not present in table "(.*?)"/i => 'não existe registro relacionado em "\1"',
      /update or delete on table "(.*?)" violates foreign key constraint/i => 'não é possível excluir ou alterar um registro de "\1" porque ele possui vínculos',
      /insert or update on table "(.*?)" violates foreign key constraint/i => 'não foi possível salvar em "\1" porque existe um relacionamento inválido',
      /Key \((.*?)\)=\((.*?)\)/i => 'campo(s) \1 com valor(es) \2',
      /relation "(.*?)" does not exist/i => 'a tabela "\1" não existe',
      /column "(.*?)" does not exist/i => 'a coluna "\1" não existe'
    }
  end
end

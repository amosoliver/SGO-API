# frozen_string_literal: true

class Result
  attr_reader :success, :value, :error, :status, :message

  def initialize(success:, value: nil, error: nil, status: nil, message: nil)
    @success = success
    @value = value
    @error = error
    @status = status || (success ? 200 : 400)
    @message = message || (success ? "Operação realizada com sucesso" : error)
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def self.success(value = nil, status = 200, message = "Operação realizada com sucesso")
    new(success: true, value: value, status: status, message: message)
  end

  def self.failure(error, status = 400, message = error)
    new(success: false, error: error, status: status, message: message)
  end
end

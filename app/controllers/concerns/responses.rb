# frozen_string_literal: true

module Responses
  extend ActiveSupport::Concern

  def tratar_resposta(result)
    if result.success?
      render_success(data: result.value, message: result.message, status: result.status)
    else
      render_error(errors: result.error, message: result.message, status: result.status)
    end
  end

  def render_success(data: {}, message: nil, status: :ok)
    render json: success_payload(message || "Operação realizada com sucesso", serialize_data(data)), status: status
  end

  def render_error(errors: [], message: nil, status: :unprocessable_entity)
    render json: error_payload(message || "Não foi possível processar a requisição", errors), status: status
  end

  def render_no_content(message: "Operação realizada com sucesso", status: :no_content)
    render json: { success: true, message: message }, status: status
  end

  private

  def serialize_data(data, serializer: nil)
    return data if data.is_a?(Hash)
    return data if data.is_a?(Array) && data.first.is_a?(Hash)

    options = {}
    if serializer
      options[:serializer] = serializer
    elsif data.respond_to?(:to_ary) && data.first.present?
      options[:each_serializer] = ActiveModel::Serializer.serializer_for(data.first)
    end

    ActiveModelSerializers::SerializableResource.new(data, options)
  end

  def success_payload(message, data)
    {
      success: true,
      message: message,
      data: data,
      timestamp: Time.current.iso8601
    }
  end

  def error_payload(message, errors)
    {
      success: false,
      message: message,
      errors: Array(errors),
      timestamp: Time.current.iso8601
    }
  end
end

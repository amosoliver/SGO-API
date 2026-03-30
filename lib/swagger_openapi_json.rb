# frozen_string_literal: true

class SwaggerOpenapiJson
  extend SwaggerBasicAuth

  def self.call(env)
    unauthorized = authenticate!(env)
    return unauthorized if unauthorized

    schema_parser = Swagger::SchemaParser.new
    controller_parser = Swagger::ControllerParser.new
    builder = Swagger::OpenapiBuilder.new(
      schema_parser,
      controller_parser,
      title: "Ambiental API",
      version: "1.0.0",
      description: "Especificacao OpenAPI dos endpoints atualmente disponiveis.",
      server_url: "/"
    )

    json = JSON.pretty_generate(builder.build)
    [200, { "Content-Type" => "application/json" }, [json]]
  rescue StandardError => e
    body = { error: "Falha ao gerar OpenAPI", detail: e.message }.to_json
    [500, { "Content-Type" => "application/json" }, [body]]
  end
end

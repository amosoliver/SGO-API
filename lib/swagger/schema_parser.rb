# frozen_string_literal: true

module Swagger
  class SchemaParser
    COLUMN_TYPE_MAP = {
      "integer" => { type: "integer", format: "int32" },
      "bigint" => { type: "integer", format: "int64" },
      "float" => { type: "number", format: "float" },
      "decimal" => { type: "number", format: "double" },
      "boolean" => { type: "boolean" },
      "datetime" => { type: "string", format: "date-time" },
      "date" => { type: "string", format: "date" },
      "json" => { type: "object", additionalProperties: true },
      "jsonb" => { type: "object", additionalProperties: true },
      "text" => { type: "string" },
      "string" => { type: "string" }
    }.freeze

    HIDDEN_COLUMNS = %w[
      encrypted_password
      reset_password_token
      reset_password_sent_at
      remember_created_at
      refresh_token
      refresh_token_expires_at
      token_primeiro_acesso
    ].freeze

    attr_reader :tables

    def initialize(schema_path = Rails.root.join("db/schema.rb"))
      @schema_path = schema_path
      @tables = parse_schema_file
    end

    def model_name_for_table(table_name)
      table_name.singularize.camelize
    end

    def to_openapi_schemas
      tables.each_with_object({}) do |(table_name, columns), schemas|
        model_name = model_name_for_table(table_name)
        writable_columns = columns.reject { |col| hidden_or_system_column?(col[:name]) }
        readable_columns = columns.reject { |col| HIDDEN_COLUMNS.include?(col[:name]) }

        schemas[model_name] = {
          type: "object",
          properties: build_properties(readable_columns)
        }

        schemas["#{model_name}Input"] = {
          type: "object",
          properties: build_properties(writable_columns.reject { |col| read_only_column?(col[:name]) })
        }

        schemas["#{model_name}List"] = {
          type: "array",
          items: { "$ref" => "#/components/schemas/#{model_name}" }
        }
      end
    end

    private

    def parse_schema_file
      content = File.read(@schema_path)

      content.scan(/create_table "([^"]+)".*? do \|t\|(.*?)^  end/m).each_with_object({}) do |(table_name, body), acc|
        acc[table_name] = body.scan(/t\.\w+\s+"([^"]+)"/).flatten.map do |column_name|
          match = body.match(/t\.(\w+)\s+"#{Regexp.escape(column_name)}"/)
          { name: column_name, type: match ? match[1] : "string" }
        end
      end
    end

    def build_properties(columns)
      columns.each_with_object({}) do |column, props|
        props[column[:name]] = COLUMN_TYPE_MAP.fetch(column[:type], { type: "string" }).dup.merge(
          description: column[:name].tr("_", " ").capitalize
        )
      end
    end

    def hidden_or_system_column?(column_name)
      HIDDEN_COLUMNS.include?(column_name)
    end

    def read_only_column?(column_name)
      %w[id created_at updated_at created_by updated_by deleted_at].include?(column_name)
    end
  end
end

# frozen_string_literal: true

require "rails/generators"
require "rails/generators/rails/scaffold/scaffold_generator"

module ApiScaffold
  class ApiScaffoldGenerator < Rails::Generators::ScaffoldGenerator
    remove_hook_for :scaffold_controller
    remove_hook_for :resource_route
    remove_hook_for :serializer

    source_root File.expand_path("templates", __dir__)

    def create_serializer_files
      template "serializer.rb.erb", File.join("app/serializers", "#{file_name}_serializer.rb")
    end

    def create_controller_files
      template "controller.rb.erb", File.join("app/controllers/api/v1", "#{controller_file_name}_controller.rb")
    end

    def add_resource_route
      routes_file = "config/routes.rb"
      content = File.read(routes_file)

      if content.match?(%r{namespace :api do.*namespace :v1 do}m)
        inject_into_file(routes_file, "      resources :#{plural_name}\n", after: /namespace :v1 do\s*\n/)
      else
        route <<~RUBY
          namespace :api do
            namespace :v1 do
              resources :#{plural_name}
            end
          end
        RUBY
      end
    end

    private

    def belongs_to_attributes
      attributes.select { |attr| attr.type == :references }
    end
  end
end

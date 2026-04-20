source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"
gem "redis", ">= 4.0.1"
gem "parallel"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"
gem "aws-sdk-s3", require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"

gem "paranoia", "~> 3.0", ">= 3.0.1"
gem "pagy"
gem "ransack"
gem "active_model_serializers"
gem "dotenv"
gem "devise", "~> 4.9"
gem "jwt"
gem "cpf_cnpj"
gem "request_store"
gem "faraday"
gem "faraday-retry"
gem "sidekiq", "~> 8.0"
gem "sidekiq-cron", "~> 2.3"
gem "spreadsheet", "~> 1.3"
gem "csv"
gem "prawn"
gem "prawn-table"
gem "wicked_pdf"
gem "wkhtmltopdf-binary"
gem "combine_pdf"
gem "fast_excel"
gem "rake", "13.4.2"
gem "caxlsx", "~> 4.4"
gem "caxlsx_rails", "~> 0.6.1"
gem "roo"
gem "paper_trail", "~> 17.0"

group :development, :test do
  gem "simplecov", require: false, group: :test
  gem "simplecov-cobertura", "~> 2.1", require: false, group: :test
  gem "byebug"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

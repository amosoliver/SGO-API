# frozen_string_literal: true

module SwaggerBasicAuth
  REALM = "Swagger".freeze

  private

  def authenticate!(env)
    return nil unless Rails.env.production?

    auth = Rack::Auth::Basic::Request.new(env)
    return unauthorized_response unless auth.provided? && auth.basic? && auth.credentials

    username, password = auth.credentials.map(&:to_s)
    expected_username = ENV.fetch("SWAGGER_USER", "admin")
    expected_password = ENV.fetch("SWAGGER_PASSWORD", "admin")

    return nil if secure_compare(username, expected_username) && secure_compare(password, expected_password)

    unauthorized_response
  end

  def secure_compare(left, right)
    return false if left.bytesize != right.bytesize

    ActiveSupport::SecurityUtils.secure_compare(left, right)
  end

  def unauthorized_response
    [
      401,
      {
        "Content-Type" => "text/plain",
        "WWW-Authenticate" => %(Basic realm="#{REALM}")
      },
      ["Autenticacao obrigatoria"]
    ]
  end
end

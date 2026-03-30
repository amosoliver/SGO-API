# lib/basic_auth_constraint.rb
class BasicAuthConstraint
  def initialize(username, password)
    @username = username.to_s
    @password = password.to_s
  end

  def matches?(request)
    auth = Rack::Auth::Basic::Request.new(request.env)
    return false unless auth.provided? && auth.basic? && auth.credentials

    username, password = auth.credentials.map(&:to_s)

    secure_compare(username, @username) && secure_compare(password, @password)
  end

  private

  def secure_compare(left, right)
    return false if left.bytesize != right.bytesize

    ActiveSupport::SecurityUtils.secure_compare(left, right)
  end
end

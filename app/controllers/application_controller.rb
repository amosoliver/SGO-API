class ApplicationController < ActionController::API
  include ActionController::Cookies
  include Pagy::Method
  include Responses
  include ExceptionHandler
  include Authenticable
  include Authorizable
end

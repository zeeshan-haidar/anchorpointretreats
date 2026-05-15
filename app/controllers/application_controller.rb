class ApplicationController < ActionController::Base
  before_action :require_password

  private

  def require_password
    # Allow health checks to bypass the password gate
    return if request.path == "/up"
    authenticate_or_request_with_http_basic("The Anchorpoint Retreat - Under Construction") do |username, password|
      username == "admin" && password == "root"
    end
  end
end

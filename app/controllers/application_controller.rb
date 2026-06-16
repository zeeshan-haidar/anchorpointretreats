class ApplicationController < ActionController::Base
  before_action :require_password

  private

  def require_password
    # Allow health checks, public AJAX endpoints, and Stripe webhooks to bypass
    public_paths = ["/up", "/availability/calendar", "/availability/pricing"]
    return if public_paths.any? { |p| request.path.start_with?(p) }
    authenticate_or_request_with_http_basic("The Anchorpoint Retreat - Under Construction") do |username, password|
      username == "admin" && password == "root"
    end
  end
end

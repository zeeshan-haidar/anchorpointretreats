class ApplicationController < ActionController::Base
  include Pagy::Method

  before_action :require_password

  private

  def require_password
    # Allow health checks, public AJAX endpoints, Stripe webhooks, and admin paths to bypass
    public_paths = ["/up", "/availability/calendar", "/availability/pricing", "/admin"]
    return if public_paths.any? { |p| request.path.start_with?(p) }
    authenticate_or_request_with_http_basic("The Anchorpoint Retreat - Under Construction") do |username, password|
      username == "admin" && password == "root"
    end
  end

  # Override Devise's after_sign_in_path to redirect admin to admin dashboard
  def after_sign_in_path_for(resource_or_scope)
    if resource_or_scope.is_a?(AdminUser)
      admin_root_path
    else
      super
    end
  end
end

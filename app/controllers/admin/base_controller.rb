# app/controllers/admin/base_controller.rb
# Base controller for all admin controllers — requires authentication + authorization

module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :authenticate_admin_user!
    check_authorization

    rescue_from CanCan::AccessDenied do |_exception|
      redirect_to admin_root_path, alert: "You are not authorized to access this area."
    end

    private

    def current_ability
      @current_ability ||= ::Ability.new(current_admin_user)
    end
  end
end

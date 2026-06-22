# app/controllers/admin/sessions_controller.rb
# Custom Devise sessions controller for admin login with admin layout

module Admin
  class SessionsController < Devise::SessionsController
    layout "admin_login"
  end
end

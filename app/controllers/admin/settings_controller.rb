# app/controllers/admin/settings_controller.rb
# Admin settings + user management (super_admin only)

module Admin
  class SettingsController < BaseController
    # GET /admin/settings/edit
    def edit
      authorize! :manage, :settings
      @admin_users = AdminUser.order(:email)
      @current_admin = current_admin_user
    end

    # PATCH /admin/settings
    def update
      authorize! :manage, :settings
      @current_admin = current_admin_user

      if @current_admin.update_with_password(admin_settings_params)
        bypass_sign_in(@current_admin)
        redirect_to admin_settings_path, notice: "Settings updated successfully."
      else
        flash.now[:alert] = "Failed to update settings: #{@current_admin.errors.full_messages.join(', ')}"
        @admin_users = AdminUser.order(:email)
        render :edit, status: :unprocessable_content
      end
    end

    private

    def admin_settings_params
      params.require(:admin_user).permit(:name, :email, :password, :password_confirmation, :current_password)
    end
  end
end

# app/controllers/admin/content_controller.rb
# Manage site content (key-value editor)

module Admin
  class ContentController < BaseController
  skip_authorization_check only: [:index, :update]
    # GET /admin/content
    def index
      @site_contents = SiteContent.order(:key)
    end

    # PATCH /admin/content/:id
    def update
      @site_content = SiteContent.find(params[:id])

      if @site_content.update(site_content_params)
        redirect_to admin_content_index_path, notice: "Content updated successfully."
      else
        flash.now[:alert] = "Failed to update content."
        render :index, status: :unprocessable_content
      end
    end

    private

    def site_content_params
      params.require(:site_content).permit(:value)
    end
  end
end

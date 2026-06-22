# app/controllers/admin/inquiries_controller.rb
# Manage inquiries

module Admin
  class InquiriesController < BaseController
    load_and_authorize_resource

    # GET /admin/inquiries
    def index
      @q = Inquiry.ransack(params[:q])
      @inquiries = @q.result
                      .order(created_at: :desc)

      @pagy, @inquiries = pagy(:offset, @inquiries, limit: 20)
    end

    # GET /admin/inquiries/:id
    def show
    end

    # PATCH /admin/inquiries/:id
    def update
      if @inquiry.update(inquiry_params)
        redirect_to admin_inquiry_path(@inquiry), notice: "Inquiry updated successfully."
      else
        flash.now[:alert] = "Failed to update inquiry."
        render :show, status: :unprocessable_content
      end
    end

    private

    def inquiry_params
      params.require(:inquiry).permit(:status, :admin_notes)
    end
  end
end

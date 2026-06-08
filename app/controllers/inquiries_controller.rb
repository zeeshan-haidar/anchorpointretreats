# app/controllers/inquiries_controller.rb
class InquiriesController < ApplicationController
  # GET /inquiry
  def new
    @inquiry = Inquiry.new
  end

  # POST /inquiry
  def create
    service = InquiryService.new
    result = service.call(inquiry_params, ip_address: request.remote_ip)

    if result.success?
      redirect_to inquiry_thank_you_path, notice: "Thank you! We'll be in touch soon."
    else
      @inquiry = result.inquiry || Inquiry.new(inquiry_params)
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  # GET /inquiry/thank-you
  def thank_you; end

  private

  def inquiry_params
    params.require(:inquiry).permit(
      :name, :email, :phone, :company, :retreat_type,
      :preferred_dates, :group_size, :message
    )
  end
end

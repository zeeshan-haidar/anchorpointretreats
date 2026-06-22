# app/controllers/admin/property_controller.rb
# GET /admin/property/edit
# PATCH /admin/property

module Admin
  class PropertyController < BaseController
  skip_authorization_check only: [:edit, :update]
    # GET /admin/property/edit
    def edit
      @property = Property.first_or_initialize
    end

    # PATCH /admin/property
    def update
      @property = Property.first_or_initialize

      if @property.update(property_params)
        redirect_to edit_admin_property_path, notice: "Property updated successfully."
      else
        flash.now[:alert] = "Failed to update property: #{@property.errors.full_messages.join(', ')}"
        render :edit, status: :unprocessable_content
      end
    end

    private

    def property_params
      params.require(:property).permit(
        :name, :tagline, :description, :short_description,
        :address, :city, :state, :zip, :latitude, :longitude,
        :bedrooms, :bathrooms, :max_guests, :square_feet,
        :base_price_cents, :cleaning_fee_cents,
        :min_nights, :max_nights, :check_in_time, :check_out_time
      )
    end
  end
end

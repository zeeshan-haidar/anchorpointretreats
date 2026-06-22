# app/controllers/admin/amenities_controller.rb
# CRUD for property amenities

module Admin
  class AmenitiesController < BaseController
  skip_authorization_check only: [:index, :new, :create, :edit, :update, :destroy]
    before_action :set_property

    # GET /admin/property/amenities
    def index
      @amenities = @property.amenities.order(sort_order: :asc)
    end

    # GET /admin/property/amenities/new
    def new
      @amenity = @property.amenities.new
    end

    # POST /admin/property/amenities
    def create
      @amenity = @property.amenities.new(amenity_params)
      max_sort = @property.amenities.maximum(:sort_order) || 0
      @amenity.sort_order = max_sort + 1

      if @amenity.save
        redirect_to admin_property_amenities_path, notice: "Amenity added successfully."
      else
        flash.now[:alert] = "Failed to add amenity: #{@amenity.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_content
      end
    end

    # GET /admin/property/amenities/:id/edit
    def edit
      @amenity = @property.amenities.find(params[:id])
    end

    # PATCH /admin/property/amenities/:id
    def update
      @amenity = @property.amenities.find(params[:id])

      if @amenity.update(amenity_params)
        redirect_to admin_property_amenities_path, notice: "Amenity updated successfully."
      else
        flash.now[:alert] = "Failed to update amenity."
        render :edit, status: :unprocessable_content
      end
    end

    # DELETE /admin/property/amenities/:id
    def destroy
      @amenity = @property.amenities.find(params[:id])
      @amenity.destroy!
      redirect_to admin_property_amenities_path, notice: "Amenity removed."
    end

    private

    def set_property
      @property = Property.first_or_initialize
    end

    def amenity_params
      params.require(:amenity).permit(:name, :description, :icon, :category, :featured, :sort_order)
    end
  end
end

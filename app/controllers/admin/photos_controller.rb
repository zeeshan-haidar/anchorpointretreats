# app/controllers/admin/photos_controller.rb
# CRUD for property photos (Active Storage)

module Admin
  class PhotosController < BaseController
  skip_authorization_check only: [:index, :new, :create, :destroy, :reorder]
    before_action :set_property

    # GET /admin/property/photos
    def index
      @photos = @property.property_images.order(sort_order: :asc)
    end

    # GET /admin/property/photos/new
    def new
      @photo = @property.property_images.new
    end

    # POST /admin/property/photos
    def create
      @photo = @property.property_images.new(photo_params)
      max_sort = @property.property_images.maximum(:sort_order) || 0
      @photo.sort_order = max_sort + 1

      if @photo.save
        redirect_to admin_property_photos_path, notice: "Photo added successfully."
      else
        flash.now[:alert] = "Failed to add photo: #{@photo.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_content
      end
    end

    # DELETE /admin/property/photos/:id
    def destroy
      @photo = @property.property_images.find(params[:id])
      @photo.image.purge if @photo.image.attached?
      @photo.destroy!
      redirect_to admin_property_photos_path, notice: "Photo removed."
    end

    # POST /admin/property/photos/reorder
    def reorder
      params[:order].each_with_index do |id, index|
        @property.property_images.find(id).update!(sort_order: index)
      end
      render json: { success: true }
    end

    private

    def set_property
      @property = Property.first_or_initialize
    end

    def photo_params
      params.require(:property_image).permit(:image, :alt_text, :caption, :category)
    end
  end
end

# app/controllers/admin/seasonal_pricings_controller.rb
# CRUD for seasonal pricing rules

module Admin
  class SeasonalPricingsController < BaseController
  skip_authorization_check only: [:index, :new, :create, :edit, :update, :destroy]
    before_action :set_property

    # GET /admin/property/pricing
    def index
      @seasonal_pricings = @property.seasonal_pricings.order(start_date: :asc)
    end

    # GET /admin/property/pricing/new
    def new
      @seasonal_pricing = @property.seasonal_pricings.new
    end

    # POST /admin/property/pricing
    def create
      @seasonal_pricing = @property.seasonal_pricings.new(seasonal_pricing_params)

      if @seasonal_pricing.save
        redirect_to admin_property_seasonal_pricings_path, notice: "Seasonal pricing added successfully."
      else
        flash.now[:alert] = "Failed to add seasonal pricing."
        render :new, status: :unprocessable_content
      end
    end

    # GET /admin/property/pricing/:id/edit
    def edit
      @seasonal_pricing = @property.seasonal_pricings.find(params[:id])
    end

    # PATCH /admin/property/pricing/:id
    def update
      @seasonal_pricing = @property.seasonal_pricings.find(params[:id])

      if @seasonal_pricing.update(seasonal_pricing_params)
        redirect_to admin_property_seasonal_pricings_path, notice: "Seasonal pricing updated."
      else
        flash.now[:alert] = "Failed to update seasonal pricing."
        render :edit, status: :unprocessable_content
      end
    end

    # DELETE /admin/property/pricing/:id
    def destroy
      @seasonal_pricing = @property.seasonal_pricings.find(params[:id])
      @seasonal_pricing.destroy!
      redirect_to admin_property_seasonal_pricings_path, notice: "Seasonal pricing removed."
    end

    private

    def set_property
      @property = Property.first_or_initialize
    end

    def seasonal_pricing_params
      params.require(:seasonal_pricing).permit(:name, :start_date, :end_date,
                                                :price_per_night_cents, :min_nights)
    end
  end
end

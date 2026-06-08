# app/controllers/availability_controller.rb
class AvailabilityController < ApplicationController
  before_action :load_property

  # GET /availability
  def index
    @property_name = @property.name
    @max_guests = @property.max_guests
    @min_nights = @property.min_nights
    @max_nights = @property.max_nights
    @base_price = @property.base_price_cents
    @cleaning_fee = @property.cleaning_fee_cents
    @deposit_percentage = @property.deposit_percentage
    @current_month = params[:month]&.to_i || Date.current.month
    @current_year = params[:year]&.to_i || Date.current.year
  end

  # GET /availability/calendar
  # Returns JSON with availability data for a given month
  def calendar
    year = params[:year] || Date.current.year
    month = params[:month] || Date.current.month

    service = AvailabilityService.new(@property)
    days = service.calendar_data(year: year, month: month)

    render json: {
      year: year.to_i,
      month: month.to_i,
      days: days,
      property: {
        max_guests: @property.max_guests,
        min_nights: @property.min_nights,
        max_nights: @property.max_nights
      }
    }
  end

  # GET /availability/pricing
  # Returns JSON with price breakdown for selected dates/guests
  def pricing
    check_in = parse_date(params[:check_in])
    check_out = parse_date(params[:check_out])
    num_guests = (params[:num_guests] || 1).to_i

    unless check_in && check_out
      render json: { success?: false, error: "Invalid dates" }, status: :unprocessable_entity
      return
    end

    service = PricingService.new(@property)
    result = service.call(check_in: check_in, check_out: check_out, num_guests: num_guests)

    render json: result.to_h
  end

  private

  def load_property
    @property = Property.first
    unless @property
      render json: { error: "No property found" }, status: :not_found
    end
  end

  def parse_date(str)
    return nil if str.blank?
    Date.parse(str)
  rescue ArgumentError
    nil
  end
end

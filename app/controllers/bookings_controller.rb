# app/controllers/bookings_controller.rb
class BookingsController < ApplicationController
  before_action :load_property
  before_action :load_booking, only: %i[payment checkout confirmation]

  # GET /book
  def new
    @check_in = parse_date(params[:check_in])
    @check_out = parse_date(params[:check_out])
    @num_guests = (params[:num_guests] || 1).to_i

    # Validate required params
    unless @check_in && @check_out
      redirect_to availability_path, alert: "Please select your dates first"
      return
    end

    # Check availability
    availability_service = AvailabilityService.new(@property)
    unless availability_service.available_for_range?(@check_in, @check_out)
      redirect_to availability_path, alert: "Selected dates are not fully available"
      return
    end

    # Get pricing for the sidebar
    pricing_service = PricingService.new(@property)
    @pricing = pricing_service.call(
      check_in: @check_in,
      check_out: @check_out,
      num_guests: @num_guests
    )

    @booking = @property.bookings.new(
      check_in: @check_in,
      check_out: @check_out,
      num_guests: @num_guests
    )
  end

  # POST /book
  def create
    check_in = parse_date(params[:check_in])
    check_out = parse_date(params[:check_out])
    num_guests = (params[:num_guests] || 1).to_i

    service = BookingService.new(@property)
    result = service.call(
      check_in: check_in,
      check_out: check_out,
      num_guests: num_guests,
      guest_name: params[:booking][:guest_name],
      guest_email: params[:booking][:guest_email],
      guest_phone: params[:booking][:guest_phone],
      company_name: params[:booking][:company_name],
      retreat_type: params[:booking][:retreat_type],
      special_requests: params[:booking][:special_requests]
    )

    if result.success?
      redirect_to booking_payment_path(result.booking)
    else
      @check_in = check_in
      @check_out = check_out
      @num_guests = num_guests
      @booking = @property.bookings.new(booking_params)
      @booking.valid?
      pricing_service = PricingService.new(@property)
      @pricing = pricing_service.call(
        check_in: check_in,
        check_out: check_out,
        num_guests: num_guests
      )
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  # GET /book/:id/payment
  def payment
    redirect_to availability_path, alert: "Booking not found" unless @booking
  end

  # POST /book/:id/checkout
  def checkout
    redirect_to availability_path, alert: "Booking not found" unless @booking

    # Stripe integration will be implemented in Phase 3
    # For now, redirect to confirmation as a placeholder
    payment_type = params[:payment_type] # "deposit" or "full"

    # Mark dates as booked only after payment is confirmed
    availability_service = AvailabilityService.new(@property)
    availability_service.mark_booked(
      check_in: @booking.check_in,
      check_out: @booking.check_out,
      booking: @booking
    )

    # Placeholder: mark as fully paid for testing
    if payment_type == "full"
      @booking.update!(status: :fully_paid, amount_paid_cents: @booking.total_cents)
    elsif payment_type == "deposit"
      @booking.update!(status: :deposit_paid, amount_paid_cents: @booking.deposit_amount_cents)
    end

    redirect_to booking_confirmation_path(@booking)
  end

  # GET /book/:id/confirmation
  def confirmation
    redirect_to availability_path, alert: "Booking not found" unless @booking
  end

  private

  def load_property
    @property = Property.first
    unless @property
      redirect_to root_path, alert: "No property configured"
    end
  end

  def load_booking
    @booking = @property.bookings.find_by(id: params[:id])
  end

  def booking_params
    params.require(:booking).permit(
      :guest_name, :guest_email, :guest_phone, :company_name,
      :retreat_type, :special_requests
    )
  end

  def parse_date(str)
    return nil if str.blank?
    Date.parse(str)
  rescue ArgumentError
    nil
  end
end

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
    redirect_to(availability_path, alert: "Booking not found") && return unless @booking

    # Ensure we respond to regular HTML (not just Turbo Stream)
    # since the payment form disables Turbo for Stripe redirect

    service = StripeCheckoutService.new
    result = service.call(
      booking: @booking,
      success_url: booking_confirmation_url(@booking),
      cancel_url: booking_payment_url(@booking)
    )

    if result.success?
      # Store the Stripe session ID on the booking
      @booking.update!(stripe_checkout_session_id: result.session_id)
      redirect_to result.checkout_url, allow_other_host: true
    else
      redirect_to booking_payment_path(@booking), alert: "Payment failed: #{result.error}"
    end
  end

  # GET /book/:id/confirmation
  def confirmation
    redirect_to availability_path, alert: "Booking not found" unless @booking

    # Fallback: if the booking is still pending but has a Stripe session,
    # try to sync with Stripe (handles missed webhooks)
    if @booking.pending? && @booking.stripe_checkout_session_id.present?
      synced = @booking.sync_with_stripe!
      if synced
        flash.now[:notice] = "Payment confirmed! Your booking is all set."
      end
    end

    # Only show confirmation for paid bookings.
    # If they have a Stripe session but sync didn't work yet (still processing),
    # let them stay on the confirmation page rather than redirecting to payment.
    if @booking.pending? && @booking.amount_paid_cents.zero? && !@booking.stripe_checkout_session_id.present?
      redirect_to booking_payment_path(@booking), alert: "Please complete payment first."
    end
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

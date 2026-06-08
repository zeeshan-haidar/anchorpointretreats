# app/services/booking_service.rb
require "ostruct"
# Creates a booking after validating availability and calculating pricing.
class BookingService
  def initialize(property)
    @property = property
  end

  # Creates a booking in a transaction
  # params: { check_in, check_out, num_guests, guest_name, guest_email,
  #           guest_phone, company_name, retreat_type, special_requests }
  def call(params)
    return OpenStruct.new(success?: false, error: "Property not found") unless @property

    check_in = params[:check_in].to_date
    check_out = params[:check_out].to_date
    num_guests = params[:num_guests].to_i

    # Validate availability
    availability_service = AvailabilityService.new(@property)
    unless availability_service.available_for_range?(check_in, check_out)
      return OpenStruct.new(success?: false, error: "Selected dates are not fully available")
    end

    # Calculate pricing
    pricing = PricingService.new(@property).call(
      check_in: check_in,
      check_out: check_out,
      num_guests: num_guests
    )
    return OpenStruct.new(success?: false, error: pricing.error) unless pricing.success?

    booking = nil

    ActiveRecord::Base.transaction do
      booking = @property.bookings.create!(
        check_in: check_in,
        check_out: check_out,
        num_guests: num_guests,
        confirmation_number: generate_confirmation_number,
        guest_name: params[:guest_name],
        guest_email: params[:guest_email],
        guest_phone: params[:guest_phone],
        company_name: params[:company_name],
        retreat_type: params[:retreat_type],
        special_requests: params[:special_requests],
        num_nights: pricing.num_nights,
        nightly_rate_cents: pricing.nightly_rate_cents,
        subtotal_cents: pricing.subtotal_cents,
        cleaning_fee_cents: pricing.cleaning_fee_cents,
        taxes_cents: pricing.taxes_cents,
        total_cents: pricing.total_cents,
        deposit_amount_cents: pricing.deposit_amount_cents,
        amount_paid_cents: 0,
        status: :pending
      )


    end

    OpenStruct.new(success?: true, booking: booking)
  rescue ActiveRecord::RecordInvalid => e
    OpenStruct.new(success?: false, error: e.record.errors.full_messages.join(", "))
  rescue StandardError => e
    OpenStruct.new(success?: false, error: e.message)
  end

  private

  def generate_confirmation_number
    loop do
      date_part = Date.current.strftime("%Y%m%d")
      random_part = SecureRandom.alphanumeric(4).upcase
      number = "AP-#{date_part}-#{random_part}"
      break number unless Booking.exists?(confirmation_number: number)
    end
  end
end

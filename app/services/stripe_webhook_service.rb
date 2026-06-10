# frozen_string_literal: true

require "ostruct"

# Processes incoming Stripe webhook events.
# Verifies the signature and handles:
#   - checkout.session.completed  → confirm booking, mark availability
#   - checkout.session.expired    → handle expired session (no-op for now)
#   - charge.refunded             → release dates, mark booking refunded
#
# Returns an OpenStruct with:
#   success?  — boolean
#   event     — the verified Stripe::Event (for logging)
#   error     — error message (if failed)
class StripeWebhookService
  # Verifies the webhook signature and constructs a Stripe::Event.
  # payload: raw request body (String)
  # sig_header: the Stripe-Signature header value
  def construct_event(payload:, sig_header:)
    secret = Rails.application.config.stripe[:signing_secret]
    return OpenStruct.new(success?: false, error: "Webhook signing secret not configured") unless secret

    event = Stripe::Webhook.construct_event(payload, sig_header, secret)
    OpenStruct.new(success?: true, event: event)
  rescue JSON::ParserError => e
    OpenStruct.new(success?: false, error: "Invalid payload: #{e.message}")
  rescue Stripe::SignatureVerificationError => e
    OpenStruct.new(success?: false, error: "Invalid signature: #{e.message}")
  end

  # Processes a verified event. Called after construct_event succeeds.
  def process_event(event)
    case event.type
    when "checkout.session.completed"
      handle_checkout_completed(event.data.object)
    when "checkout.session.expired"
      handle_checkout_expired(event.data.object)
    when "charge.refunded"
      handle_charge_refunded(event.data.object)
    else
      OpenStruct.new(success?: true, message: "Unhandled event type: #{event.type}")
    end
  end

  private

  # On successful checkout (full payment only):
  # 1. Look up the booking by metadata.booking_id
  # 2. Store the Stripe session ID and payment intent ID on the booking
  # 3. Update status to fully_paid
  # 4. Update amount_paid
  # 5. Mark availability dates as booked
  # 6. Send confirmation email
  def handle_checkout_completed(session)
    booking_id = session.metadata.booking_id
    booking = Booking.find_by(id: booking_id)

    return OpenStruct.new(success?: false, error: "Booking #{booking_id} not found") unless booking
    return OpenStruct.new(success?: true, message: "Booking #{booking.confirmation_number} already processed") unless booking.pending?

    property = booking.property
    amount_paid = session.amount_total || 0

    ActiveRecord::Base.transaction do
      # Store Stripe references
      booking.update!(
        stripe_checkout_session_id: session.id,
        stripe_payment_intent_id: session.payment_intent,
        amount_paid_cents: amount_paid,
        status: :fully_paid
      )

      # Mark availability as booked
      AvailabilityService.new(property).mark_booked(
        check_in: booking.check_in,
        check_out: booking.check_out,
        booking: booking
      )
    end

    # Send confirmation email (outside transaction to avoid db lock)
    BookingMailer.confirmation(booking).deliver_later

    OpenStruct.new(success?: true, message: "Booking #{booking.confirmation_number} confirmed (full payment)")
  rescue ActiveRecord::RecordInvalid => e
    OpenStruct.new(success?: false, error: "Failed to update booking: #{e.message}")
  rescue StandardError => e
    OpenStruct.new(success?: false, error: "Unexpected error: #{e.message}")
  end

  # On checkout session expiry: no action needed for now.
  # The booking remains in "pending" status and will be cleaned up
  # by the PendingBookingCleanupJob.
  def handle_checkout_expired(session)
    booking_id = session.metadata&.booking_id
    if booking_id
      booking = Booking.find_by(id: booking_id)
      Rails.logger.info "[StripeWebhook] Checkout session expired for booking #{booking&.confirmation_number || booking_id}"
    end
    OpenStruct.new(success?: true, message: "Expired session acknowledged")
  end

  # On charge refunded:
  # 1. Look up booking by payment intent
  # 2. Update status to refunded
  # 3. Release availability dates
  def handle_charge_refunded(charge)
    payment_intent = charge.payment_intent
    booking = Booking.find_by(stripe_payment_intent_id: payment_intent)

    return OpenStruct.new(success?: false, error: "Booking not found for payment intent #{payment_intent}") unless booking

    property = booking.property

    ActiveRecord::Base.transaction do
      booking.update!(status: :refunded)

      AvailabilityService.new(property).mark_available(
        check_in: booking.check_in,
        check_out: booking.check_out
      )
    end

    OpenStruct.new(success?: true, message: "Booking #{booking.confirmation_number} refunded")
  rescue ActiveRecord::RecordInvalid => e
    OpenStruct.new(success?: false, error: "Failed to process refund: #{e.message}")
  end
end

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
    notify_stripe_error("Webhook Invalid Payload", e)
    OpenStruct.new(success?: false, error: "Invalid payload: #{e.message}")
  rescue Stripe::SignatureVerificationError => e
    notify_stripe_error("Webhook Invalid Signature", e)
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

    # Notify #stripe-notifications about successful payment
    notify_stripe_success(
      "Payment Received",
      "Booking #{booking.confirmation_number} fully paid — #{booking.guest_name}",
      booking: booking,
      amount_paid: amount_paid
    )

    OpenStruct.new(success?: true, message: "Booking #{booking.confirmation_number} confirmed (full payment)")
  rescue ActiveRecord::RecordInvalid => e
    notify_stripe_error("Webhook Checkout Failed - DB Error", e, booking: booking)
    OpenStruct.new(success?: false, error: "Failed to update booking: #{e.message}")
  rescue StandardError => e
    notify_stripe_error("Webhook Checkout Failed", e, booking: booking)
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

      # Notify #stripe-notifications about expired session
      notify_stripe_notification(
        "Checkout Expired",
        "Payment session expired for booking #{booking&.confirmation_number || booking_id}",
        fields: {
          "Booking ID" => booking_id.to_s,
          "Confirmation" => booking&.confirmation_number.to_s,
          "Guest" => booking&.guest_name.to_s
        },
        color: :warning
      )
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
    refund_amount_cents = booking.amount_paid_cents

    ActiveRecord::Base.transaction do
      booking.update!(status: :refunded, amount_paid_cents: 0)

      AvailabilityService.new(property).mark_available(
        check_in: booking.check_in,
        check_out: booking.check_out
      )
    end

    # Only send refund confirmation email if admin hasn't already sent one
    unless booking.admin_notes&.include?("Refunded via admin panel")
      BookingMailer.refund_confirmation(booking, refund_amount_cents: refund_amount_cents).deliver_later
    end

    # Notify #stripe-notifications about refund
    notify_stripe_success(
      "Refund Processed",
      "Booking #{booking.confirmation_number} refunded — #{booking.guest_name}",
      booking: booking,
      refund_amount: refund_amount_cents
    )

    OpenStruct.new(success?: true, message: "Booking #{booking.confirmation_number} refunded")
  rescue ActiveRecord::RecordInvalid => e
    notify_stripe_error("Webhook Refund Failed - DB Error", e, booking: booking)
    OpenStruct.new(success?: false, error: "Failed to process refund: #{e.message}")
  end

  # --- Slack notification helpers ---

  # Sends a success notification to the #stripe-notifications channel
  def notify_stripe_success(title, message, booking: nil, amount_paid: nil, refund_amount: nil)
    fields = {}
    if booking
      fields["Booking ID"] = booking.id.to_s
      fields["Confirmation"] = booking.confirmation_number.to_s
      fields["Guest"] = booking.guest_name.to_s
      fields["Check-in"] = booking.check_in.to_s
      fields["Check-out"] = booking.check_out.to_s
    end
    fields["Amount Paid"] = "$#{format('%.2f', (amount_paid || 0) / 100.0)}" if amount_paid
    fields["Refund Amount"] = "$#{format('%.2f', (refund_amount || 0) / 100.0)}" if refund_amount

    notify_stripe_notification(title, message, fields: fields, color: :good)
  end

  # Sends an error notification to the #stripe-errors channel
  def notify_stripe_error(title, exception, booking: nil)
    webhook_url = ENV.fetch("SLACK_WEBHOOK_URL_STRIPE_ERRORS", ENV.fetch("SLACK_WEBHOOK_URL", nil))
    return unless webhook_url

    notifier = SlackNotifier.new(title, channel: SlackNotifier::CHANNEL_STRIPE_ERRORS, webhook_url: webhook_url)

    fields = {
      "Error" => "#{exception.class}: #{exception.message}",
      "Service" => "StripeWebhookService"
    }

    if booking
      fields["Booking ID"] = booking.id.to_s
      fields["Confirmation"] = booking.confirmation_number.to_s
    end

    notifier.post(
      "Stripe webhook error on #{Rails.env.upcase}",
      fields: fields,
      color: :danger
    )
  rescue StandardError => slack_error
    Rails.logger.warn "[StripeWebhookService] Failed to notify Slack: #{slack_error.message}"
  end

  # Generic notification to #stripe-notifications channel
  def notify_stripe_notification(title, message, fields: {}, color: :good)
    webhook_url = ENV.fetch("SLACK_WEBHOOK_URL_STRIPE_NOTIFICATIONS", ENV.fetch("SLACK_WEBHOOK_URL", nil))
    return unless webhook_url

    notifier = SlackNotifier.new(title, channel: SlackNotifier::CHANNEL_STRIPE_NOTIFICATIONS, webhook_url: webhook_url)

    notifier.post(
      message,
      fields: fields,
      color: color
    )
  rescue StandardError => slack_error
    Rails.logger.warn "[StripeWebhookService] Failed to notify Slack: #{slack_error.message}"
  end
end

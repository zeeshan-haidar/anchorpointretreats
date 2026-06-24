# frozen_string_literal: true

require "ostruct"

class StripeCheckoutService
  def call(booking:, success_url:, cancel_url:)
    return OpenStruct.new(success?: false, error: "Booking is required") unless booking
    return OpenStruct.new(success?: false, error: "Booking is not pending") unless booking.pending?

    amount = booking.total_cents

    session = Stripe::Checkout::Session.create(
      {
        mode: "payment",
        customer_email: booking.guest_email,
        client_reference_id: booking.id.to_s,
        expires_at: (Time.current + 30.minutes).to_i,
        line_items: [
          {
            quantity: 1,
            price_data: {
              currency: "usd",
              unit_amount: amount,
              product_data: {
                name: "The Anchorpoint Retreat — #{booking.confirmation_number}",
                description: "Full payment · #{booking.check_in.strftime('%b %d')} – #{booking.check_out.strftime('%b %d, %Y')} · #{booking.num_nights} nights · #{booking.num_guests} #{'guest'.pluralize(booking.num_guests)}"
              }
            }
          }
        ],
        metadata: {
          booking_id: booking.id.to_s,
          confirmation_number: booking.confirmation_number
        },
        success_url: success_url,
        cancel_url: cancel_url,
        payment_method_options: {
          card: {
            request_three_d_secure: "any"
          }
        },
        payment_method_types: ["card", "cashapp", "amazon_pay"]
      }
    )

    # Notify #stripe-notifications about checkout session creation
    notify_stripe_notification(
      "Checkout Created",
      "Payment session created for #{booking.guest_name} — Booking #{booking.confirmation_number}",
      fields: {
        "Booking ID" => booking.id.to_s,
        "Confirmation" => booking.confirmation_number.to_s,
        "Guest" => booking.guest_name.to_s,
        "Amount" => "$#{format('%.2f', amount / 100.0)}",
        "Check-in" => booking.check_in.to_s,
        "Check-out" => booking.check_out.to_s
      },
      color: :good
    )

    OpenStruct.new(
      success?: true,
      checkout_url: session.url,
      session_id: session.id
    )
  rescue Stripe::StripeError => e
    notify_stripe_error("Stripe Checkout Error", e, booking: booking)
    OpenStruct.new(success?: false, error: e.message)
  end

  private

  # Sends an error notification to the #stripe-errors channel
  def notify_stripe_error(title, exception, booking: nil)
    webhook_url = ENV.fetch("SLACK_WEBHOOK_URL_STRIPE_ERRORS", ENV.fetch("SLACK_WEBHOOK_URL", nil))
    return unless webhook_url

    notifier = SlackNotifier.new(title, channel: SlackNotifier::CHANNEL_STRIPE_ERRORS, webhook_url: webhook_url)

    fields = {
      "Error" => "#{exception.class}: #{exception.message}",
      "Service" => "StripeCheckoutService"
    }

    if booking
      fields["Booking ID"] = booking.id.to_s
      fields["Confirmation"] = booking.confirmation_number.to_s
      fields["Amount"] = "$#{format('%.2f', booking.total_cents / 100.0)}"
    end

    notifier.post(
      "Stripe checkout error on #{Rails.env.upcase}",
      fields: fields,
      color: :danger
    )
  rescue StandardError => slack_error
    Rails.logger.warn "[StripeCheckoutService] Failed to notify Slack: #{slack_error.message}"
  end

  # Sends a notification to the #stripe-notifications channel
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
    Rails.logger.warn "[StripeCheckoutService] Failed to notify Slack: #{slack_error.message}"
  end
end

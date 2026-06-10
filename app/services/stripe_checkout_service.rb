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
        payment_method_types: ["card", "cashapp", "amazon_pay"]      }
    )

    OpenStruct.new(
      success?: true,
      checkout_url: session.url,
      session_id: session.id
    )
  rescue Stripe::StripeError => e
    OpenStruct.new(success?: false, error: e.message)
  end
end

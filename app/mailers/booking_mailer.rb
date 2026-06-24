# frozen_string_literal: true

# Sends transactional emails related to bookings.
#   confirmation   — sent to the guest after successful payment
#   reminder       — sent 7 days before check-in (triggered by Sidekiq job)
#   refund_confirmation — sent when a booking is refunded
class BookingMailer < ApplicationMailer
  include ActionView::Helpers::NumberHelper

  # Email: Booking Confirmation
  # Sent to guest after successful Stripe payment (from webhook).
  # Includes confirmation number, dates, amount paid, check-in instructions.
  def confirmation(booking)
    @booking = booking
    @property = booking.property
    @amount_paid = ActionController::Base.helpers.number_to_currency(booking.amount_paid_cents / 100.0)
    @balance_due = ActionController::Base.helpers.number_to_currency(booking.balance_due_cents / 100.0) if booking.balance_due_cents > 0

    mail(
      to: booking.guest_email,
      subject: "Booking Confirmed — #{booking.confirmation_number} — The Anchorpoint Retreat"
    )
  end

  # Email: Booking Reminder
  # Sent 7 days before check-in via Sidekiq scheduled job.
  def reminder(booking)
    @booking = booking
    @property = booking.property

    mail(
      to: booking.guest_email,
      subject: "Your Stay at The Anchorpoint Retreat Starts Soon! (#{booking.confirmation_number})"
    )
  end

  # Email: Refund Confirmation
  # Sent to guest when a booking is refunded via admin or Stripe webhook.
  # Informs the guest of the refund amount and expected timeline.
  def refund_confirmation(booking, refund_amount_cents: nil)
    @booking = booking
    @property = booking.property
    amount = refund_amount_cents || booking.amount_paid_cents
    @refund_amount = ActionController::Base.helpers.number_to_currency(amount / 100.0)

    mail(
      to: booking.guest_email,
      subject: "Refund Processed — #{booking.confirmation_number} — The Anchorpoint Retreat"
    )
  end

  # Email: Cancellation Notice
  # Sent to guest when their pending booking is auto-cancelled due to non-payment.
  # Informs them that their booking session expired and they can rebook if interested.
  def cancellation_notice(booking)
    @booking = booking
    @property = booking.property

    mail(
      to: booking.guest_email,
      subject: "Booking Session Expired — #{booking.confirmation_number} — The Anchorpoint Retreat"
    )
  end
end

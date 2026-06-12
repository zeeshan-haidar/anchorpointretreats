# frozen_string_literal: true

# Sends transactional emails related to bookings.
#   confirmation   — sent to the guest after successful payment
#   reminder       — sent 7 days before check-in (triggered by Sidekiq job)
#   payment_link   — sent to collect remaining balance (admin-triggered)
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
  # Sent to guest when a booking is refunded via Stripe webhook.
  # Informs the guest of the refund amount and expected timeline.
  def refund_confirmation(booking)
    @booking = booking
    @property = booking.property
    @refund_amount = ActionController::Base.helpers.number_to_currency(booking.amount_paid_cents / 100.0)

    mail(
      to: booking.guest_email,
      subject: "Refund Processed — #{booking.confirmation_number} — The Anchorpoint Retreat"
    )
  end

  # Email: Payment Reminder
  # Sent to collect remaining balance on deposit-paid bookings.
  def payment_link(booking, payment_url)
    @booking = booking
    @property = booking.property
    @balance_due = ActionController::Base.helpers.number_to_currency(booking.balance_due_cents / 100.0)
    @payment_url = payment_url

    mail(
      to: booking.guest_email,
      subject: "Payment Reminder — Balance Due for #{booking.confirmation_number}"
    )
  end
end

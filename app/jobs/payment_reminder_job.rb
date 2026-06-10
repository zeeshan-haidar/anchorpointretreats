# frozen_string_literal: true

# Scheduled job that sends payment reminder emails for deposit-paid bookings
# that are 30 days away from check-in.
#
# This is a future enhancement placeholder — the full implementation requires
# generating a new Stripe Checkout Session for the remaining balance.
#
# Runs daily via Sidekiq Cron (config/sidekiq.yml):
#   payment_reminder:
#     cron: "0 9 * * *"  # 9 AM daily
#     class: PaymentReminderJob
#     queue: default
class PaymentReminderJob
  include Sidekiq::Job
  sidekiq_options retry: 2, queue: :default

  def perform
    # Find deposit-paid bookings with check-in approximately 30 days away
    target_date = Date.current + 30.days
    bookings = Booking.where(check_in: target_date)
                      .where(status: :deposit_paid)

    bookings.find_each do |booking|
      # Create a new Checkout Session for the remaining balance
      service = StripeCheckoutService.new
      result = service.call(
        booking: booking,
        payment_type: "full",
        success_url: "#{Rails.application.config.action_mailer.default_url_options[:host]}/book/#{booking.id}/confirmation",
        cancel_url: "#{Rails.application.config.action_mailer.default_url_options[:host]}/book/#{booking.id}/payment"
      )

      if result.success?
        payment_url = result.checkout_url
        BookingMailer.payment_link(booking, payment_url).deliver_later
      else
        Rails.logger.warn "[PaymentReminderJob] Failed to create payment link for booking #{booking.confirmation_number}: #{result.error}"
      end
    end

    Rails.logger.info "[PaymentReminderJob] Sent #{bookings.count} payment reminder(s) for #{target_date}"
  end
end

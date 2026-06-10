# frozen_string_literal: true

# Scheduled job that sends booking reminder emails 7 days before check-in.
# Runs daily via Sidekiq Cron (or can be triggered manually from admin panel).
#
# Configuration (config/sidekiq.yml):
#   booking_reminder:
#     cron: "0 8 * * *"  # 8 AM daily
#     class: BookingReminderJob
#     queue: default
class BookingReminderJob
  include Sidekiq::Job
  sidekiq_options retry: 2, queue: :default

  def perform
    # Find bookings with check-in exactly 7 days from today
    target_date = Date.current + 7.days
    bookings = Booking.where(check_in: target_date)
                      .where(status: %i[deposit_paid fully_paid confirmed])

    bookings.find_each do |booking|
      BookingMailer.reminder(booking).deliver_later
    end

    Rails.logger.info "[BookingReminderJob] Sent #{bookings.count} reminder(s) for #{target_date}"
  end
end

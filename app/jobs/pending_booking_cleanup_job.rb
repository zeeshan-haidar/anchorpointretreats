# frozen_string_literal: true

# Scheduled job that cleans up unpaid pending bookings older than 30 minutes.
# Runs every 15 minutes via Sidekiq scheduled jobs.
#
# For pending bookings that have exceeded the 30-minute window:
#   1. Cancels the booking (status → cancelled)
#   2. Releases any held availability dates
#   3. Sends a notification email to the guest
#
# Configuration (config/sidekiq.yml):
#   pending_booking_cleanup:
#     cron: "*/15 * * * *"        # Every 15 minutes
#     class: PendingBookingCleanupJob
#     queue: default
class PendingBookingCleanupJob
  include Sidekiq::Job
  sidekiq_options retry: 2, queue: :default

  def perform
    # Find pending bookings older than 30 minutes
    cutoff_time = Time.current - 30.minutes
    expired_bookings = Booking.where(status: :pending)
                              .where("created_at < ?", cutoff_time)

    count = 0
    expired_bookings.find_each do |booking|
      cancel_expired_booking(booking)
      count += 1
    end

    Rails.logger.info "[PendingBookingCleanupJob] Cancelled #{count} expired pending booking(s)"
  rescue StandardError => e
    Rails.logger.error "[PendingBookingCleanupJob] Error: #{e.class}: #{e.message}"
    # Re-raise so Sidekiq retries and the error handler notifies Slack
    raise e
  end

  private

  def cancel_expired_booking(booking)
    booking.transaction do
      # Release any availability dates that might have been marked as booked
      # (this handles edge cases where availability was set before payment)
      if booking.availabilities.any?
        AvailabilityService.new(booking.property).mark_available(
          check_in: booking.check_in,
          check_out: booking.check_out
        )
      end

      # Cancel the booking
      booking.update!(status: :cancelled, admin_notes: "Auto-cancelled: unpaid after 30 minutes")
    end

    # Send cancellation notification outside the transaction
    BookingMailer.cancellation_notice(booking).deliver_later

    Rails.logger.info "[PendingBookingCleanupJob] Cancelled booking #{booking.confirmation_number} (#{booking.guest_email})"
  rescue StandardError => e
    Rails.logger.error "[PendingBookingCleanupJob] Failed to cancel booking ##{booking.id}: #{e.message}"
    raise e
  end
end

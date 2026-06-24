# frozen_string_literal: true

# Sidekiq configuration
# Queue names:
#   default    — general purpose jobs (email delivery, reminders)
#
# Scheduled jobs (via sidekiq.yml or sidekiq-cron):
#   booking_reminder — daily at 8 AM
#   pending_booking_cleanup — every 15 minutes

sidekiq_config = {
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
  network_timeout: 5
}

Sidekiq.configure_server do |config|
  config.redis = sidekiq_config

  # Add custom error handling middleware for Slack notifications
  config.server_middleware do |chain|
    chain.add "SidekiqErrorHandler"
  end

  # Reload the app in development when a job runs
  if Rails.env.development?
    config.client_middleware do |chain|
      # No client middleware needed for now
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_config
end

# Schedule recurring jobs
# Uses Sidekiq's built-in scheduled sets via sidekiq.yml
# For more complex scheduling, add the sidekiq-cron gem
sidekiq_schedule = {
  booking_reminder: {
    cron: "0 8 * * *",      # Every day at 8 AM
    class: "BookingReminderJob",
    queue: :default,
    description: "Send booking reminder emails 7 days before check-in"
  },
  pending_booking_cleanup: {
    cron: "*/15 * * * *",    # Every 15 minutes
    class: "PendingBookingCleanupJob",
    queue: :default,
    description: "Cancel pending bookings older than 30 minutes"
  }
}

# If using sidekiq-cron, register the schedule
if defined?(Sidekiq::Cron::Job)
  sidekiq_schedule.each do |name, config|
    Sidekiq::Cron::Job.create(name: name.to_s, **config) unless Sidekiq::Cron::Job.exists?(name.to_s)
  end
end

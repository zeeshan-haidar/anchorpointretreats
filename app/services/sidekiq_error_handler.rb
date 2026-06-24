# frozen_string_literal: true

# Sidekiq server middleware that catches job failures and notifies Slack.
#
# Usage in config/initializers/sidekiq.rb:
#   Sidekiq.configure_server do |config|
#     config.server_middleware do |chain|
#       chain.add SidekiqErrorHandler
#     end
#   end
#
# This middleware wraps every job execution and:
#   1. Measures job duration
#   2. Rescues exceptions
#   3. Sends Slack notification with job details
#   4. Re-raises the exception for Sidekiq's built-in retry mechanism
class SidekiqErrorHandler
  # Sidekiq server middleware interface
  def call(worker, job, queue)
    started_at = Time.current

    yield # Execute the job

    duration = Time.current - started_at

    # Log slow jobs (over 30 seconds) as a warning
    if duration > 30
      notifier = SlackNotifier.new("Slow Job Alert", channel: SlackNotifier::CHANNEL_ALERTS)
      notifier.post(
        "Job `#{worker.class}` ran for #{duration.round(2)}s on queue `#{queue}`",
        fields: {
          "Worker" => worker.class.to_s,
          "Queue" => queue.to_s,
          "Duration" => "#{duration.round(2)}s",
          "JID" => job["jid"],
          "Args" => sanitize_args(job["args"])
        },
        color: :warning
      )
    end
  rescue StandardError => e
    duration = Time.current - started_at

    # Notify Slack about the failure
    notify_job_failure(worker, job, queue, e, duration)

    # Re-raise so Sidekiq can retry as configured
    raise e
  end

  private

  def notify_job_failure(worker, job, queue, exception, duration)
    # Route Stripe-related job failures to dedicated channel
    if stripe_related_job?(worker, exception)
      channel = SlackNotifier::CHANNEL_STRIPE_ERRORS
    else
      channel = SlackNotifier::CHANNEL_ALERTS
    end

    notifier = SlackNotifier.new("Job Failed: #{worker.class}", channel: channel, webhook_url: SlackNotifier.webhook_url_for(channel))

    fields = {
      "Error" => "#{exception.class}: #{exception.message}",
      "Worker" => worker.class.to_s,
      "Queue" => queue.to_s,
      "Duration" => "#{duration.round(2)}s",
      "JID" => job["jid"],
      "Retry Count" => (job["retry_count"] || 0).to_s,
      "Args" => sanitize_args(job["args"])
    }

    if exception.backtrace
      fields["Backtrace"] = exception.backtrace.first(5).join("\n")
    end

    notifier.post(
      "Background job failed on #{Rails.env.upcase} after #{duration.round(2)}s",
      fields: fields,
      color: :danger
    )
  rescue StandardError => slack_error
    Rails.logger.warn "[SidekiqErrorHandler] Failed to notify Slack: #{slack_error.message}"
  end

  # Determines if a failed job is related to Stripe
  def stripe_related_job?(worker, exception)
    worker.class.to_s.match?(/stripe/i) ||
      exception.class.name.start_with?("Stripe::") ||
      exception.message.match?(/stripe/i)
  end

  # Sanitize job arguments to avoid sending sensitive data to Slack
  def sanitize_args(args)
    args.map do |arg|
      case arg
      when Hash
        arg.map { |k, v| %w[password token secret card number cvv].include?(k.to_s) ? { k => "[FILTERED]" } : { k => v } }.reduce(:merge)
      else
        arg.to_s.truncate(200)
      end
    end.to_s.truncate(500)
  rescue StandardError
    "[unable to sanitize]"
  end
end

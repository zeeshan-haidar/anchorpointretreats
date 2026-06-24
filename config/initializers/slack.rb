# frozen_string_literal: true

# Slack configuration
# The webhook URL is set via the SLACK_WEBHOOK_URL environment variable.
#
# To set up:
#   1. Create a Slack app and enable Incoming Webhooks
#   2. Add a webhook to your desired channel
#   3. Set the webhook URL:
#      export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
#
# Optional variables:
#   SLACK_CHANNEL  — default channel to post to (default: "#general")
#   SLACK_USERNAME — bot username (default: "Anchorpoint Bot")

unless Rails.env.test?
  webhook_url = ENV["SLACK_WEBHOOK_URL"]
  if webhook_url.blank?
    Rails.logger.warn "[Slack] SLACK_WEBHOOK_URL is not configured. Slack notifications will be logged but not sent."
  elsif !webhook_url.start_with?("https://hooks.slack.com/")
    Rails.logger.warn "[Slack] SLACK_WEBHOOK_URL does not appear to be a valid Slack webhook URL."
  end
end

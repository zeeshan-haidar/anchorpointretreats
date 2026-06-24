# frozen_string_literal: true

require "net/http"
require "ostruct"
require "json"

# Sends notifications to a Slack channel via incoming webhook.
# Uses the SLACK_WEBHOOK_URL environment variable to configure the webhook endpoint.
#
# Usage:
#   SlackNotifier.new("Booking Alert").post("A new booking was created!")
#   SlackNotifier.new("Exception", "#urgent").post(
#     "Something went wrong",
#     fields: { "Error" => "NoMethodError", "Backtrace" => "..." }
#   )
#
# The webhook URL is automatically loaded from ENV["SLACK_WEBHOOK_URL"].
# If not configured, notifications are silently logged (no crash).
class SlackNotifier
  # Channel names — configurable via environment variables
  CHANNEL_ALERTS = (ENV["SLACK_CHANNEL_ALERTS"].presence || "#alerts").freeze
  CHANNEL_STRIPE_ERRORS = (ENV["SLACK_CHANNEL_STRIPE_ERRORS"].presence || "#stripe-errors").freeze
  CHANNEL_STRIPE_NOTIFICATIONS = (ENV["SLACK_CHANNEL_STRIPE_NOTIFICATIONS"].presence || "#stripe-notifications").freeze
  CHANNEL_DEFAULT = (ENV["SLACK_CHANNEL_DEFAULT"].presence || "#general").freeze

  # Webhook URLs — configurable per channel via environment variables.
  # Each falls back to SLACK_WEBHOOK_URL, then to nil (silent log).
  WEBHOOK_URL_DEFAULT = (ENV["SLACK_WEBHOOK_URL"] || ENV["SLACK_WEBHOOK_URL_ALERTS"]).freeze
  WEBHOOK_URL_ALERTS = (ENV["SLACK_WEBHOOK_URL_ALERTS"] || ENV["SLACK_WEBHOOK_URL"]).freeze
  WEBHOOK_URL_STRIPE_ERRORS = (ENV["SLACK_WEBHOOK_URL_STRIPE_ERRORS"] || ENV["SLACK_WEBHOOK_URL_STRIPE"] || ENV["SLACK_WEBHOOK_URL"]).freeze
  WEBHOOK_URL_STRIPE_NOTIFICATIONS = (ENV["SLACK_WEBHOOK_URL_STRIPE_NOTIFICATIONS"] || ENV["SLACK_WEBHOOK_URL_STRIPE"] || ENV["SLACK_WEBHOOK_URL"]).freeze

  USERNAME = "Anchorpoint Bot".freeze
  ICON_EMOJI = ":house:".freeze

  # Resolves the appropriate webhook URL for a given channel name.
  # Allows different channels to use different webhook URLs.
  def self.webhook_url_for(channel)
    case channel
    when CHANNEL_ALERTS then WEBHOOK_URL_ALERTS
    when CHANNEL_STRIPE_ERRORS then WEBHOOK_URL_STRIPE_ERRORS
    when CHANNEL_STRIPE_NOTIFICATIONS then WEBHOOK_URL_STRIPE_NOTIFICATIONS
    else WEBHOOK_URL_DEFAULT
    end
  end

  def initialize(title, channel: nil, webhook_url: nil)
    @title = title
    @channel = channel || CHANNEL_DEFAULT
    @webhook_url = webhook_url || self.class.webhook_url_for(@channel) || ENV.fetch("SLACK_WEBHOOK_URL", nil)
  end

  # Sends a notification to Slack.
  # message:  The main text body (required)
  # fields:   Hash of key-value pairs to display as Slack message fields (optional)
  # color:    Color for the sidebar stripe — use :good (green), :warning (yellow), :danger (red), or hex
  def post(message, fields: {}, color: :danger)
    unless @webhook_url
      Rails.logger.info "[SlackNotifier] Webhook URL not configured. Skipping notification: #{@title} — #{message}"
      return OpenStruct.new(success?: false, error: "Webhook URL not configured")
    end

    payload = build_payload(message, fields, color)

    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 5
    http.read_timeout = 5

    request = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" })
    request.body = payload.to_json

    response = http.request(request)

    if response.code.to_i == 200
      OpenStruct.new(success?: true, message: "Notification sent to Slack")
    else
      Rails.logger.warn "[SlackNotifier] Slack API returned #{response.code}: #{response.body}"
      OpenStruct.new(success?: false, error: "Slack API error: #{response.code}")
    end
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.warn "[SlackNotifier] Timeout sending to Slack: #{e.message}"
    OpenStruct.new(success?: false, error: "Timeout: #{e.message}")
  rescue StandardError => e
    Rails.logger.warn "[SlackNotifier] Failed to send Slack notification: #{e.message}"
    OpenStruct.new(success?: false, error: e.message)
  end

  private

  def build_payload(message, fields, color)
    color_code = case color
                 when :good then "#36a64f"
                 when :warning then "#ffcc00"
                 when :danger then "#cc0000"
                 else color.to_s
                 end

    attachment = {
      fallback: "#{@title}: #{message}",
      color: color_code,
      title: @title,
      text: message,
      footer: ENV.fetch("APP_HOST", "Anchorpoint Retreat"),
      footer_icon: "https://platform.slack-edge.com/img/default_application_icon.png",
      ts: Time.current.to_i
    }

    if fields.present?
      attachment[:fields] = fields.map do |key, value|
        { title: key.to_s, value: value.to_s, short: value.to_s.length < 50 }
      end
    end

    {
      channel: @channel,
      username: USERNAME,
      icon_emoji: ICON_EMOJI,
      attachments: [attachment]
    }
  end
end

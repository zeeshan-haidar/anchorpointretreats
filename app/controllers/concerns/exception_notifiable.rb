# frozen_string_literal: true

# Concern for controller-level exception handling with Slack notification.
# Include in ApplicationController (or any controller) to catch unhandled
# exceptions, log them, and send alerts to Slack.
#
# Provides:
#   - rescue_from for StandardError (and custom handlers)
#   - Slack notification with context (request URL, params, user agent)
#   - User-friendly 404, 500 error pages
#
# Usage:
#   class ApplicationController < ActionController::Base
#     include ExceptionNotifiable
#   end
module ExceptionNotifiable
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActionController::RoutingError, with: :render_not_found
    rescue_from ActionController::UnknownFormat, with: :render_not_acceptable
    rescue_from CanCan::AccessDenied, with: :render_forbidden
    rescue_from StandardError, with: :render_internal_server_error
  end

  private

  def render_not_found(exception)
    notify_slack(exception, :warning)
    respond_to_error("Page not found", :not_found)
  end

  def render_not_acceptable(exception)
    notify_slack(exception, :warning)
    respond_to_error("Unsupported format", :not_acceptable)
  end

  def render_forbidden(exception)
    notify_slack(exception, :warning)
    respond_to_error("Access denied", :forbidden)
  end

  def render_internal_server_error(exception)
    notify_slack(exception, :danger)
    respond_to_error("Something went wrong. Please try again later.", :internal_server_error)
  end

  def respond_to_error(message, status)
    respond_to do |format|
      format.html do
        # Render a static error page if available, otherwise a simple text response
        file = Rails.public_path.join("#{status}.html")
        if File.exist?(file)
          render file: file, layout: false, status: status, locals: { message: message }
        else
          render html: "<h1>#{status}</h1><p>#{message}</p>".html_safe,
                 layout: false,
                 status: status
        end
      end
      format.json { render json: { error: message }, status: status }
      format.turbo_stream do
        render html: "<turbo-stream action=\"replace\" target=\"flash\">" \
                     "<template>#{ERB::Util.html_escape(message)}</template>" \
                     "</turbo-stream>".html_safe,
               status: status
      end
    end
  end

  # Sends exception details to Slack with request context.
  def notify_slack(exception, severity = :danger)
    # Don't notify in test environment
    return if Rails.env.test?

    # Build contextual information
    fields = {
      "Error" => "#{exception.class}: #{exception.message}",
      "URL" => request.original_url,
      "Method" => request.method,
      "Params" => filtered_params,
      "User Agent" => request.user_agent,
      "Remote IP" => request.remote_ip
    }

    # Include the first 5 lines of the backtrace
    if exception.backtrace
      fields["Backtrace"] = exception.backtrace.first(5).join("\n")
    end

    # Route Stripe-related exceptions to the dedicated #stripe-errors channel
    if stripe_related_exception?(exception)
      channel = SlackNotifier::CHANNEL_STRIPE_ERRORS
    else
      channel = SlackNotifier::CHANNEL_ALERTS
    end

    notifier = SlackNotifier.new("Exception: #{controller_name}##{action_name}", channel: channel, webhook_url: SlackNotifier.webhook_url_for(channel))
    notifier.post("An exception occurred on #{Rails.env.upcase} — #{request.original_url}", fields: fields, color: severity)
  rescue StandardError => e
    Rails.logger.warn "[ExceptionNotifiable] Failed to notify Slack: #{e.message}"
  end

  # Determines if an exception is related to Stripe integration
  def stripe_related_exception?(exception)
    exception.class.name.start_with?("Stripe::") ||
      controller_name.match?(/\Awebhooks\z/i) ||
      controller_name.match?(/\Astripe/i) ||
      exception.message.match?(/stripe/i)
  end

  # Returns filtered params (excluding sensitive fields like password, token, secret)
  def filtered_params
    params.except(:controller, :action).to_unsafe_h.map do |key, value|
      %w[password token secret card number cvv].include?(key.to_s) ? [key, "[FILTERED]"] : [key, value]
    end.to_h
  end
end

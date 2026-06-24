# frozen_string_literal: true

# Rack middleware that detects unhandled exceptions by checking the response
# status code. When the app returns a 500 response, it sends a notification
# to Slack. This catches all errors including SyntaxError, NoMethodError, etc.
#
# Rails' DebugExceptions middleware catches all exceptions and returns a 500
# response (with the debug error page in development), so the exception never
# propagates to outer middleware. By checking the status code after the
# response, we can notify about ALL server errors.
#
# The exception details (class, message, backtrace) are parsed from the HTML
# response body that Rails generates.
class SlackErrorNotifier
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    notify_slack(env, status, body) if status >= 500
    [status, headers, body]
  end

  private

  def notify_slack(env, status, body)
    return if Rails.env.test?

    url = env["REQUEST_URI"] || env["PATH_INFO"] || "unknown"
    method = env["REQUEST_METHOD"] || "?"

    # Extract exception info from the response body
    body_content = extract_body(body)
    exception_info = parse_exception_from_body(body_content)

    fields = {
      "URL" => url,
      "Method" => method,
      "Remote IP" => env["REMOTE_ADDR"] || "?"
    }

    if exception_info
      fields["Error"] = exception_info[:class]
      fields["Message"] = exception_info[:message]
      fields["Backtrace"] = exception_info[:backtrace] if exception_info[:backtrace]
    end

    webhook_url = SlackNotifier::WEBHOOK_URL_ALERTS
    return unless webhook_url

    notifier = SlackNotifier.new(
      "#{status} Error on #{Rails.env.upcase}",
      channel: SlackNotifier::CHANNEL_ALERTS,
      webhook_url: webhook_url
    )

    notifier.post(
      "An error occurred — #{url}",
      fields: fields,
      color: :danger
    )
  rescue StandardError => e
    Rails.logger.warn "[SlackErrorNotifier] Failed to notify Slack: #{e.message}"
  end

  def extract_body(body)
    content = +""
    body.each { |chunk| content << chunk.to_s }
    content
  end

  def parse_exception_from_body(body)
    return nil if body.nil? || body.empty?

    # Rails error pages have the exception class in the <h1> tag
    # and the message in the .message div
    if body =~ %r{<h1>(.*?)</h1>}m
      exception_class = $1.strip

      # Extract the message from the .message div
      message_match = body.match(%r{<div class="message">(.*?)</div>}m)
      message = message_match ? $1.strip.gsub(%r{<br\s*/?>}, "\n") : ""

      # Extract the first few lines of the backtrace from the Application Trace section
      backtrace_match = body.match(%r{<div id="Application-Trace-0"[^>]*>(.*?)</div>}m)
      backtrace = if backtrace_match
                    $1.gsub(%r{<[^>]+>}, "").strip
                  end

      {
        class: exception_class,
        message: message,
        backtrace: backtrace
      }
    end
  rescue StandardError
    nil
  end
end

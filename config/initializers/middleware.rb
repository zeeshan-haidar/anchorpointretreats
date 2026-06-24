# frozen_string_literal: true

require_relative "../../lib/slack_error_notifier"

# Insert SlackErrorNotifier as the outermost middleware to catch all exceptions
# (including SyntaxError, NoMethodError, etc.) that occur during request processing.
# This catches errors that Rails' rescue_from (StandardError only) misses.
Rails.application.config.middleware.insert_before 0, SlackErrorNotifier

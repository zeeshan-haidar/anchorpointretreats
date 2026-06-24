# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = Rails.root.join("spec", "vcr_cassettes")
  config.hook_into :webmock
  config.ignore_localhost = true
  config.ignore_hosts(
    "localhost",
    "127.0.0.1"
  )
  # Filter sensitive data
  config.filter_sensitive_data("<STRIPE_PUBLISHABLE_KEY>") { ENV["STRIPE_PUBLISHABLE_KEY"] }
  config.filter_sensitive_data("<STRIPE_SECRET_KEY>") { ENV["STRIPE_SECRET_KEY"] }
  config.filter_sensitive_data("<STRIPE_WEBHOOK_SIGNING_SECRET>") { ENV["STRIPE_WEBHOOK_SIGNING_SECRET"] }
  config.filter_sensitive_data("<SLACK_WEBHOOK_URL>") { ENV["SLACK_WEBHOOK_URL"] }
end

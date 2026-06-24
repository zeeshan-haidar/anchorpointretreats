# frozen_string_literal: true

# Only configure WebMock, don't use webmock/rspec which requires rspec-expectations
# This avoids ordering issues. The WebMock helpers will be included via config.
require "webmock"

RSpec.configure do |config|
  config.include WebMock::API
end

# Allow connections to localhost and Stripe API for VCR tests
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: [
    "api.stripe.com",
    "localhost",
    "127.0.0.1",
    /\.stripe\.com/
  ]
)

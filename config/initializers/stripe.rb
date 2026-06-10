# frozen_string_literal: true

# Stripe configuration
# Keys are set via environment variables:
#   STRIPE_PUBLISHABLE_KEY  (or pk_test_xxx default)
#   STRIPE_SECRET_KEY       (or sk_test_xxx default)
#   STRIPE_WEBHOOK_SIGNING_SECRET  (for webhook signature verification)

Rails.application.config.stripe = {
  publishable_key: ENV.fetch("STRIPE_PUBLISHABLE_KEY", "pk_test_placeholder"),
  secret_key: ENV.fetch("STRIPE_SECRET_KEY", "sk_test_placeholder"),
  signing_secret: ENV.fetch("STRIPE_WEBHOOK_SIGNING_SECRET", nil)
}

Stripe.api_key = Rails.application.config.stripe[:secret_key]

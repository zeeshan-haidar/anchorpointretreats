# frozen_string_literal: true

# Handles incoming Stripe webhook events.
# All routes are POST and skip CSRF protection (Stripe doesn't send CSRF tokens).
# Signature verification is handled by StripeWebhookService.
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :require_password

  # POST /webhooks/stripe
  # Receives Stripe webhook events, verifies the signature,
  # and processes the event (confirm booking, mark availability, send emails).
  def stripe
    payload = request.body.read
    sig_header = request.headers["Stripe-Signature"]

    service = StripeWebhookService.new

    # Verify signature
    result = service.construct_event(payload: payload, sig_header: sig_header)
    unless result.success?
      render json: { error: result.error }, status: :bad_request
      return
    end

    # Process the event
    process_result = service.process_event(result.event)
    unless process_result.success?
      render json: { error: process_result.error }, status: :unprocessable_entity
      return
    end

    render json: { status: "success", message: process_result.message }, status: :ok
  end
end

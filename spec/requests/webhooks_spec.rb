# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Webhooks", type: :request do
  describe "POST /webhooks/stripe" do
    let(:payload) { '{"id":"evt_test","type":"checkout.session.completed"}' }
    let(:sig_header) { "t=123,v1=abc" }

    before do
      # Stub the webhook service to avoid hitting Stripe
      allow_any_instance_of(StripeWebhookService).to receive(:construct_event).and_return(
        double(success?: true, event: double(type: "checkout.session.completed", data: double(object: double(id: "cs_test"))))
      )
      allow_any_instance_of(StripeWebhookService).to receive(:process_event).and_return(
        double(success?: true, message: "Processed successfully")
      )
    end

    it "returns http success" do
      post "/webhooks/stripe",
           params: payload,
           headers: { "Stripe-Signature" => sig_header, "Content-Type" => "application/json" }
      expect(response).to have_http_status(:success)
    end

    it "returns a JSON response" do
      post "/webhooks/stripe",
           params: payload,
           headers: { "Stripe-Signature" => sig_header, "Content-Type" => "application/json" }
      expect(response.content_type).to match(/json/)
    end

    context "when signature verification fails" do
      before do
        allow_any_instance_of(StripeWebhookService).to receive(:construct_event).and_return(
          double(success?: false, error: "Invalid signature")
        )
      end

      it "returns bad request" do
        post "/webhooks/stripe",
             params: payload,
             headers: { "Stripe-Signature" => "bad", "Content-Type" => "application/json" }
        expect(response).to have_http_status(:bad_request)
      end

      it "returns error message in JSON" do
        post "/webhooks/stripe",
             params: payload,
             headers: { "Stripe-Signature" => "bad", "Content-Type" => "application/json" }
        parsed = response.parsed_body
        expect(parsed["error"]).to include("Invalid signature")
      end
    end

    context "when event processing fails" do
      before do
        allow_any_instance_of(StripeWebhookService).to receive(:construct_event).and_return(
          double(success?: true, event: double(type: "checkout.session.completed", data: double(object: double(id: "cs_test"))))
        )
        allow_any_instance_of(StripeWebhookService).to receive(:process_event).and_return(
          double(success?: false, error: "Booking not found")
        )
      end

      it "returns unprocessable entity" do
        post "/webhooks/stripe",
             params: payload,
             headers: { "Stripe-Signature" => sig_header, "Content-Type" => "application/json" }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it "skips CSRF protection" do
      # This should work without a CSRF token
      post "/webhooks/stripe",
           params: payload,
           headers: { "Stripe-Signature" => sig_header, "Content-Type" => "application/json" }
      expect(response).to have_http_status(:success)
    end
  end
end

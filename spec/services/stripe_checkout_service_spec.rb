# frozen_string_literal: true

require "rails_helper"

RSpec.describe StripeCheckoutService, type: :service do
  subject(:service) { described_class.new }

  let(:property) { create(:property) }
  let(:booking) { create(:booking, property: property, status: :pending) }

  let(:success_url) { "http://example.com/book/#{booking.id}/confirmation" }
  let(:cancel_url) { "http://example.com/book/#{booking.id}/payment" }

  before do
    # Stub Stripe API calls so we don't hit the real API
    allow(Stripe::Checkout::Session).to receive(:create).and_return(
      double(
        id: "cs_test_abc123",
        url: "https://checkout.stripe.com/pay/cs_test_abc123"
      )
    )
  end

  describe "#call" do
    context "with valid params" do
      let(:result) do
        service.call(
          booking: booking,
          success_url: success_url,
          cancel_url: cancel_url
        )
      end

      it "returns success" do
        expect(result.success?).to be true
      end

      it "returns a checkout URL" do
        expect(result.checkout_url).to eq("https://checkout.stripe.com/pay/cs_test_abc123")
      end

      it "returns a session ID" do
        expect(result.session_id).to eq("cs_test_abc123")
      end

      it "calls Stripe with total amount" do
        result
        expect(Stripe::Checkout::Session).to have_received(:create) do |params|
          expect(params[:line_items][0][:price_data][:unit_amount]).to eq(booking.total_cents)
        end
      end
    end

    context "with nil booking" do
      it "returns failure" do
        result = service.call(
          booking: nil,
          success_url: success_url,
          cancel_url: cancel_url
        )
        expect(result.success?).to be false
        expect(result.error).to include("Booking is required")
      end
    end

    context "with non-pending booking" do
      before { booking.update!(status: :fully_paid) }

      it "returns failure" do
        result = service.call(
          booking: booking,
          success_url: success_url,
          cancel_url: cancel_url
        )
        expect(result.success?).to be false
        expect(result.error).to include("not pending")
      end
    end

    context "when Stripe raises an error" do
      before do
        allow(Stripe::Checkout::Session).to receive(:create).and_raise(
          Stripe::StripeError.new("API error")
        )
      end

      it "returns failure with error message" do
        result = service.call(
          booking: booking,
          success_url: success_url,
          cancel_url: cancel_url
        )
        expect(result.success?).to be false
        expect(result.error).to include("API error")
      end
    end

    it "sets metadata on the Stripe session" do
      service.call(
        booking: booking,
        success_url: success_url,
        cancel_url: cancel_url
      )

      expect(Stripe::Checkout::Session).to have_received(:create) do |params|
        expect(params[:metadata][:booking_id]).to eq(booking.id.to_s)
        expect(params[:metadata][:confirmation_number]).to eq(booking.confirmation_number)
      end
    end

    it "sets customer email on the Stripe session" do
      service.call(
        booking: booking,
        success_url: success_url,
        cancel_url: cancel_url
      )

      expect(Stripe::Checkout::Session).to have_received(:create) do |params|
        expect(params[:customer_email]).to eq(booking.guest_email)
      end
    end

    it "restricts payment methods to card only" do
      service.call(
        booking: booking,
        success_url: success_url,
        cancel_url: cancel_url
      )

      expect(Stripe::Checkout::Session).to have_received(:create) do |params|
        expect(params[:payment_method_types]).to eq(["card", "cashapp", "amazon_pay"])
      end
    end

  end
end

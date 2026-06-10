# frozen_string_literal: true

require "rails_helper"

RSpec.describe StripeWebhookService, type: :service do
  subject(:service) { described_class.new }

  let(:property) { create(:property) }
  let(:booking) { create(:booking, property: property, status: :pending) }

  describe "#construct_event" do
    it "returns failure without signing secret configured" do
      result = service.construct_event(payload: "{}", sig_header: "t=123,v1=abc")
      expect(result.success?).to be false
      expect(result.error).to include("signing secret not configured")
    end
  end

  describe "#process_event" do
    let(:session) do
      double(
        "Stripe::Checkout::Session",
        id: "cs_test_123",
        payment_intent: "pi_test_123",
        amount_total: booking.total_cents,
        metadata: double(
          booking_id: booking.id.to_s,
          payment_type: "full",
          confirmation_number: booking.confirmation_number
        )
      )
    end

    context "with checkout.session.completed" do
      let(:event) { double("Stripe::Event", type: "checkout.session.completed", data: double(object: session)) }

      before do
        allow(BookingMailer).to receive_message_chain(:confirmation, :deliver_later)
      end

      it "updates the booking status to fully_paid" do
        service.process_event(event)
        expect(booking.reload.status).to eq("fully_paid")
      end

      it "updates amount_paid_cents" do
        service.process_event(event)
        expect(booking.reload.amount_paid_cents).to eq(booking.total_cents)
      end

      it "stores the Stripe session ID" do
        service.process_event(event)
        expect(booking.reload.stripe_checkout_session_id).to eq("cs_test_123")
      end

      it "stores the payment intent ID" do
        service.process_event(event)
        expect(booking.reload.stripe_payment_intent_id).to eq("pi_test_123")
      end

      it "sends a confirmation email" do
        expect(BookingMailer).to receive(:confirmation).with(booking).and_return(double(deliver_later: true))
        service.process_event(event)
      end

      context "when booking is already processed" do
        before do
          booking.update!(status: :fully_paid)
          # Clear expectation from before block
          allow(BookingMailer).to receive(:confirmation).and_return(double(deliver_later: true))
        end

        it "does not re-process" do
          expect(BookingMailer).not_to receive(:confirmation)
          result = service.process_event(event)
          expect(result.success?).to be true
          expect(result.message).to include("already processed")
        end
      end
    end

    context "with checkout.session.expired" do
      let(:session) do
        double("Stripe::Checkout::Session", id: "cs_test_expired", metadata: double(booking_id: booking.id.to_s))
      end
      let(:event) { double("Stripe::Event", type: "checkout.session.expired", data: double(object: session)) }

      it "returns success without changing booking status" do
        expect(service.process_event(event).success?).to be true
        expect(booking.reload.status).to eq("pending")
      end
    end

    context "with charge.refunded" do
      let(:charge) do
        double("Stripe::Charge", payment_intent: "pi_test_refund")
      end
      let(:event) { double("Stripe::Event", type: "charge.refunded", data: double(object: charge)) }

      before do
        booking.update!(
          stripe_payment_intent_id: "pi_test_refund",
          status: :fully_paid,
          amount_paid_cents: booking.total_cents
        )
      end

      it "updates booking status to refunded" do
        service.process_event(event)
        expect(booking.reload.status).to eq("refunded")
      end
    end

    context "with unhandled event type" do
      let(:event) { double("Stripe::Event", type: "unknown.event", data: double(object: double(id: "test"))) }

      it "returns success without error" do
        result = service.process_event(event)
        expect(result.success?).to be true
        expect(result.message).to include("Unhandled event type")
      end
    end
  end
end

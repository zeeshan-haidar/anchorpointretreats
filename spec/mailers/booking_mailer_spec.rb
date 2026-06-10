# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookingMailer, type: :mailer do
  let(:property) { create(:property) }
  let(:booking) { create(:booking, property: property, status: :fully_paid) }

  describe "#confirmation" do
    subject(:mail) { described_class.confirmation(booking) }

    it "renders the headers" do
      expect(mail.subject).to include("Booking Confirmed")
      expect(mail.subject).to include(booking.confirmation_number)
      expect(mail.to).to eq([booking.guest_email])
      expect(mail.from).to eq(["hello@anchorpointretreat.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(booking.confirmation_number)
      expect(mail.body.encoded).to match(booking.guest_name)
      expect(mail.body.encoded).to match(property.name)
    end

    it "includes the check-in and check-out dates" do
      expect(mail.body.encoded).to match(booking.check_in.strftime("%B %d"))
      expect(mail.body.encoded).to match(booking.check_out.strftime("%B %d"))
    end

    context "with a deposit-paid booking" do
      let(:booking) { create(:booking, property: property, status: :deposit_paid) }

      it "includes balance due information" do
        expect(mail.body.encoded).to match("Balance Due")
        expect(mail.body.encoded).to include("5,262.25")
      end
    end
  end

  describe "#reminder" do
    subject(:mail) { described_class.reminder(booking) }

    it "renders the headers" do
      expect(mail.subject).to include("Your Stay")
      expect(mail.subject).to include(booking.confirmation_number)
      expect(mail.to).to eq([booking.guest_email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(booking.guest_name)
      expect(mail.body.encoded).to match(booking.check_in.strftime("%B %d"))
    end
  end

  describe "#payment_link" do
    let(:payment_url) { "https://checkout.stripe.com/pay/test_link" }
    subject(:mail) { described_class.payment_link(booking, payment_url) }

    it "renders the headers" do
      expect(mail.subject).to include("Payment Reminder")
      expect(mail.subject).to include(booking.confirmation_number)
      expect(mail.to).to eq([booking.guest_email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(booking.guest_name)
      expect(mail.body.encoded).to match(payment_url)
    end
  end
end

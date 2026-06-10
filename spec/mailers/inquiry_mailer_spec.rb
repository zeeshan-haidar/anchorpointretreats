# frozen_string_literal: true

require "rails_helper"

RSpec.describe InquiryMailer, type: :mailer do
  let(:inquiry) { create(:inquiry) }

  describe "#received" do
    subject(:mail) { described_class.received(inquiry) }

    it "renders the headers" do
      expect(mail.subject).to include("Thank You")
      expect(mail.subject).to include("The Anchorpoint Retreat")
      expect(mail.to).to eq([inquiry.email])
      expect(mail.from).to eq(["hello@anchorpointretreat.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(inquiry.name)
    end
  end

  describe "#new_inquiry_alert" do
    let(:admin_email) { "admin@anchorpointretreat.com" }
    subject(:mail) { described_class.new_inquiry_alert(inquiry, admin_email) }

    it "renders the headers" do
      expect(mail.subject).to include("New Inquiry")
      expect(mail.subject).to include(inquiry.name)
      expect(mail.to).to eq([admin_email])
    end

    it "renders the body with inquiry details" do
      expect(mail.body.encoded).to match(inquiry.name)
      expect(mail.body.encoded).to match(inquiry.email)
      expect(mail.body.encoded).to match(inquiry.message)
    end
  end
end

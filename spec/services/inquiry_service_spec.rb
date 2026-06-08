require "rails_helper"

RSpec.describe InquiryService, type: :service do
  subject(:service) { described_class.new }

  describe "#call" do
    let(:valid_params) do
      {
        name: "Jane Smith",
        email: "jane@example.com",
        phone: "(555) 987-6543",
        company: "Wellness Co.",
        retreat_type: "wellness",
        preferred_dates: "August 2026",
        group_size: 8,
        message: "We're interested in booking a wellness retreat."
      }
    end

    context "with valid params" do
      it "creates an inquiry" do
        result = service.call(valid_params)
        expect(result.success?).to be true
        expect(result.inquiry).to be_persisted
      end

      it "sets default status to new_inquiry" do
        result = service.call(valid_params)
        expect(result.inquiry.status).to eq("new_inquiry")
      end

      it "saves the message" do
        result = service.call(valid_params)
        expect(result.inquiry.message).to eq("We're interested in booking a wellness retreat.")
      end
    end

    context "with missing name" do
      let(:invalid_params) { valid_params.merge(name: nil) }

      it "returns an error" do
        result = service.call(invalid_params)
        expect(result.success?).to be false
        expect(result.error).to include("Name")
      end
    end

    context "with missing email" do
      let(:invalid_params) { valid_params.merge(email: nil) }

      it "returns an error" do
        result = service.call(invalid_params)
        expect(result.success?).to be false
        expect(result.error).to include("Email")
      end
    end

    context "with invalid email format" do
      let(:invalid_params) { valid_params.merge(email: "bad-email") }

      it "returns an error" do
        result = service.call(invalid_params)
        expect(result.success?).to be false
        expect(result.error).to include("Email")
      end
    end

    context "with missing message" do
      let(:invalid_params) { valid_params.merge(message: nil) }

      it "returns an error" do
        result = service.call(invalid_params)
        expect(result.success?).to be false
        expect(result.error).to include("Message")
      end
    end
  end
end

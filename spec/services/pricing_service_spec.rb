require "rails_helper"

RSpec.describe PricingService, type: :service do
  let(:property) { FactoryBot.create(:property) }
  subject(:service) { described_class.new(property) }

  describe "#call" do
    let(:check_in) { Date.current + 30.days }
    let(:check_out) { check_in + 3.days }
    let(:num_guests) { 4 }

    context "with valid params" do
      it "returns success" do
        result = service.call(check_in: check_in, check_out: check_out, num_guests: num_guests)
        expect(result.success?).to be true
      end

      it "calculates the correct number of nights" do
        result = service.call(check_in: check_in, check_out: check_out, num_guests: num_guests)
        expect(result.num_nights).to eq(3)
      end

      it "calculates the nightly rate from base price" do
        result = service.call(check_in: check_in, check_out: check_out, num_guests: num_guests)
        expect(result.nightly_rate_cents).to eq(property.base_price_cents)
      end

      it "calculates subtotal correctly" do
        result = service.call(check_in: check_in, check_out: check_out, num_guests: num_guests)
        expected_subtotal = property.base_price_cents * 3
        expect(result.subtotal_cents).to eq(expected_subtotal)
      end

      it "includes cleaning fee" do
        result = service.call(check_in: check_in, check_out: check_out, num_guests: num_guests)
        expect(result.cleaning_fee_cents).to eq(property.cleaning_fee_cents)
      end

      it "calculates total correctly (subtotal + cleaning + taxes)" do
        result = service.call(check_in: check_in, check_out: check_out, num_guests: num_guests)
        expected_total = (property.base_price_cents * 3) + property.cleaning_fee_cents
        expected_taxes = ((expected_total) * 0.085).round
        expect(result.total_cents).to eq(expected_total + expected_taxes)
      end

      it "calculates deposit as 25% of total" do
        result = service.call(check_in: check_in, check_out: check_out, num_guests: num_guests)
        expected_deposit = (result.total_cents * 0.25).round
        expect(result.deposit_amount_cents).to eq(expected_deposit)
      end
    end

    context "when check_out is before check_in" do
      let(:check_out) { check_in - 1.day }

      it "returns an error" do
        result = service.call(check_in: check_in, check_out: check_out, num_guests: num_guests)
        expect(result.success?).to be false
        expect(result.error).to include("Check-out must be after check-in")
      end
    end

    context "when guests exceed maximum" do
      let(:num_guests) { property.max_guests + 1 }

      it "returns an error" do
        result = service.call(check_in: check_in, check_out: check_out, num_guests: num_guests)
        expect(result.success?).to be false
        expect(result.error).to include("Guest count exceeds maximum")
      end
    end

    context "when the stay is below minimum nights" do
      let(:check_out) { check_in + 1.day }

      it "returns an error" do
        result = service.call(check_in: check_in, check_out: check_out, num_guests: num_guests)
        expect(result.success?).to be false
        expect(result.error).to include("Minimum stay")
      end
    end

    context "with seasonal pricing overrides" do
      let!(:seasonal) do
        FactoryBot.create(:seasonal_pricing, property: property,
               start_date: check_in, end_date: check_out,
               price_per_night_cents: 250_000, min_nights: 3)
      end

      it "uses the seasonal nightly rate" do
        result = service.call(check_in: check_in, check_out: check_out, num_guests: num_guests)
        expect(result.nightly_rate_cents).to eq(250_000)
      end
    end
  end
end

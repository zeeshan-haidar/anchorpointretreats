require "rails_helper"

RSpec.describe BookingService, type: :service do
  let(:property) { FactoryBot.create(:property) }
  subject(:service) { described_class.new(property) }

  describe "#call" do
    let(:check_in) { Date.current + 30.days }
    let(:check_out) { check_in + 3.days }
    let(:valid_params) do
      {
        check_in: check_in,
        check_out: check_out,
        num_guests: 4,
        guest_name: "John Doe",
        guest_email: "john@example.com",
        guest_phone: "(555) 123-4567",
        company_name: "Acme Corp",
        retreat_type: "corporate",
        special_requests: "Looking forward to it!"
      }
    end

    before do
      (check_in...check_out).each do |date|
        FactoryBot.create(:availability, property: property, date: date, status: :available)
      end
    end

    context "with valid params" do
      it "creates a booking" do
        result = service.call(valid_params)
        expect(result.success?).to be true
        expect(result.booking).to be_persisted
        expect(result.booking.guest_name).to eq("John Doe")
      end

      it "generates a confirmation number" do
        result = service.call(valid_params)
        expect(result.booking.confirmation_number).to be_present
        expect(result.booking.confirmation_number).to start_with("AP-")
      end

      it "sets the correct dates" do
        result = service.call(valid_params)
        expect(result.booking.check_in).to eq(check_in)
        expect(result.booking.check_out).to eq(check_out)
      end

      it "marks the associated availability as booked" do
        result = service.call(valid_params)
        availabilities = property.availabilities.for_range(check_in, check_out)
        expect(availabilities.pluck(:status)).to all(eq("booked"))
        expect(availabilities.pluck(:booking_id)).to all(eq(result.booking.id))
      end

      it "sets status to pending" do
        result = service.call(valid_params)
        expect(result.booking.status).to eq("pending")
      end

      it "calculates pricing correctly" do
        result = service.call(valid_params)
        booking = result.booking
        expect(booking.num_nights).to eq(3)
        expect(booking.total_cents).to be > 0
        expect(booking.deposit_amount_cents).to be > 0
      end
    end

    context "when dates are not fully available" do
      let(:bad_check_in) { Date.current + 60.days }
      let(:bad_check_out) { bad_check_in + 3.days }
      let(:bad_params) { valid_params.merge(check_in: bad_check_in, check_out: bad_check_out) }

      before do
        (bad_check_in...bad_check_out).each_with_index do |date, idx|
          status = idx == 1 ? :booked : :available
          FactoryBot.create(:availability, property: property, date: date, status: status)
        end
      end

      it "returns an error" do
        result = service.call(bad_params)
        expect(result.success?).to be false
        expect(result.error).to include("not fully available")
      end

      it "does not create a booking" do
        expect do
          service.call(bad_params)
        end.not_to change(Booking, :count)
      end
    end

    context "with missing guest name" do
      let(:invalid_params) { valid_params.merge(guest_name: nil) }

      it "returns an error" do
        result = service.call(invalid_params)
        expect(result.success?).to be false
        expect(result.error).to be_present
      end
    end

    context "with invalid email" do
      let(:invalid_params) { valid_params.merge(guest_email: "not-an-email") }

      it "returns an error" do
        result = service.call(invalid_params)
        expect(result.success?).to be false
        expect(result.error).to be_present
      end
    end
  end
end

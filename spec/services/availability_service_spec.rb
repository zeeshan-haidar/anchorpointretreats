require "rails_helper"

RSpec.describe AvailabilityService, type: :service do
  let(:property) { FactoryBot.create(:property) }
  subject(:service) { described_class.new(property) }

  describe "#calendar_data" do
    let(:year) { Date.current.year }
    let(:month) { Date.current.month }

    context "when there are availabilities" do
      let!(:available_date) do
        FactoryBot.create(:availability, property: property,
               date: Date.new(year, month, 15), status: :available)
      end
      let!(:booked_date) do
        FactoryBot.create(:availability, property: property,
               date: Date.new(year, month, 20), status: :booked)
      end

      it "returns an array of day data for the entire month" do
        result = service.calendar_data(year: year, month: month)
        expect(result).to be_an(Array)
        expect(result.length).to eq(Date.new(year, month, -1).day)
      end

      it "includes the correct status for known dates" do
        result = service.calendar_data(year: year, month: month)
        day15 = result.find { |d| d[:date] == available_date.date }
        day20 = result.find { |d| d[:date] == booked_date.date }

        expect(day15[:status]).to eq("available")
        expect(day20[:status]).to eq("booked")
      end

      it "marks dates without records as available" do
        result = service.calendar_data(year: year, month: month)
        # A date with no availability record should default to available
        day1 = result.find { |d| d[:day] == 1 }
        expect(day1[:status]).to eq("available")
      end

      it "marks past dates correctly" do
        result = service.calendar_data(year: year, month: month)
        # Some past date should be marked as past
        past_dates = result.select { |d| d[:past] }
        expect(past_dates).to be_any
      end
    end
  end

  describe "#available_for_range?" do
    let(:check_in) { Date.current + 30.days }
    let(:check_out) { check_in + 3.days }

    context "when all dates are available" do
      before do
        (check_in...check_out).each do |date|
          FactoryBot.create(:availability, property: property, date: date, status: :available)
        end
      end

      it "returns true" do
        expect(service.available_for_range?(check_in, check_out)).to be true
      end
    end

    context "when some dates are booked" do
      before do
        (check_in...check_out).each_with_index do |date, idx|
          status = idx == 1 ? :booked : :available
          FactoryBot.create(:availability, property: property, date: date, status: status)
        end
      end

      it "returns false" do
        expect(service.available_for_range?(check_in, check_out)).to be false
      end
    end

    context "when dates are blocked" do
      before do
        FactoryBot.create(:availability, property: property, date: check_in, status: :blocked)
        FactoryBot.create(:availability, property: property, date: check_in + 1, status: :blocked)
        FactoryBot.create(:availability, property: property, date: check_in + 2, status: :blocked)
      end

      it "returns false" do
        expect(service.available_for_range?(check_in, check_out)).to be false
      end
    end
  end

  describe "#mark_booked" do
    let(:check_in) { Date.current + 30.days }
    let(:check_out) { check_in + 2.days }
    let(:booking) { FactoryBot.create(:booking, property: property) }

    before do
      (check_in...check_out).each do |date|
        FactoryBot.create(:availability, property: property, date: date, status: :available)
      end
    end

    it "marks the date range as booked" do
      service.mark_booked(check_in: check_in, check_out: check_out, booking: booking)
      availabilities = property.availabilities.for_range(check_in, check_out)
      expect(availabilities.pluck(:status)).to all(eq("booked"))
    end

    it "associates the booking with the availabilities" do
      service.mark_booked(check_in: check_in, check_out: check_out, booking: booking)
      availabilities = property.availabilities.for_range(check_in, check_out)
      expect(availabilities.pluck(:booking_id)).to all(eq(booking.id))
    end
  end

  describe "#mark_available" do
    let(:check_in) { Date.current + 30.days }
    let(:check_out) { check_in + 2.days }
    let(:booking) { FactoryBot.create(:booking, property: property) }

    before do
      (check_in...check_out).each do |date|
        FactoryBot.create(:availability, property: property, date: date,
               status: :booked, booking_id: booking.id)
      end
    end

    it "marks the date range as available" do
      service.mark_available(check_in: check_in, check_out: check_out)
      availabilities = property.availabilities.for_range(check_in, check_out)
      expect(availabilities.pluck(:status)).to all(eq("available"))
    end

    it "removes the booking association" do
      service.mark_available(check_in: check_in, check_out: check_out)
      availabilities = property.availabilities.for_range(check_in, check_out)
      expect(availabilities.pluck(:booking_id)).to all(be_nil)
    end
  end
end

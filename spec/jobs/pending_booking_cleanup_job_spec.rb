# frozen_string_literal: true

require "rails_helper"

RSpec.describe PendingBookingCleanupJob, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.new }

  let(:property) { create(:property) }

  describe "#perform" do
    context "when there are expired pending bookings" do
      let!(:expired_booking) do
        create(:booking,
               property: property,
               status: :pending,
               created_at: 45.minutes.ago)
      end

      let!(:recent_booking) do
        create(:booking,
               property: property,
               status: :pending,
               created_at: 5.minutes.ago)
      end

      let!(:paid_booking) do
        create(:booking,
               property: property,
               status: :fully_paid,
               created_at: 2.hours.ago)
      end

      it "cancels expired pending bookings" do
        expect {
          job.perform
        }.to change { expired_booking.reload.status }.from("pending").to("cancelled")
      end

      it "does not cancel recent pending bookings" do
        expect {
          job.perform
        }.not_to change { recent_booking.reload.status }
      end

      it "does not cancel non-pending bookings" do
        expect {
          job.perform
        }.not_to change { paid_booking.reload.status }
      end

      it "sets admin notes on cancelled bookings" do
        job.perform
        expect(expired_booking.reload.admin_notes).to include("Auto-cancelled")
      end

      it "sends a cancellation email" do
        expect(BookingMailer).to receive(:cancellation_notice).with(expired_booking).and_return(
          double("mail", deliver_later: true)
        )

        job.perform
      end

      it "does not send cancellation email for non-expired bookings" do
        # Allow the expired booking to be sent normally
        allow(BookingMailer).to receive(:cancellation_notice).with(expired_booking).and_return(
          double("mail", deliver_later: true)
        )

        expect(BookingMailer).not_to receive(:cancellation_notice).with(recent_booking)
        expect(BookingMailer).not_to receive(:cancellation_notice).with(paid_booking)

        job.perform
      end
    end

    context "when there are no expired bookings" do
      let!(:recent_booking) do
        create(:booking,
               property: property,
               status: :pending,
               created_at: 10.minutes.ago)
      end

      it "does nothing" do
        expect {
          job.perform
        }.not_to change { recent_booking.reload.status }
      end

      it "logs the result" do
        expect(Rails.logger).to receive(:info).with(/Cancelled 0 expired/)
        job.perform
      end
    end

    context "when a booking has availability dates marked" do
      let!(:expired_booking) do
        create(:booking,
               property: property,
               status: :pending,
               created_at: 45.minutes.ago)
      end

      before do
        # Simulate some availability dates linked to this booking
        (expired_booking.check_in...expired_booking.check_out).each do |date|
          create(:availability,
                 property: property,
                 date: date,
                 status: :booked,
                 booking: expired_booking)
        end
      end

      it "releases the availability dates" do
        job.perform

        expired_booking.reload.availabilities.each do |availability|
          expect(availability.status).to eq("available")
          expect(availability.booking_id).to be_nil
        end
      end
    end
  end
end

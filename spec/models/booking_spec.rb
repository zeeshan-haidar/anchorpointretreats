# == Schema Information
#
# Table name: bookings
#
#  id                         :bigint           not null, primary key
#  admin_notes                :text
#  amount_paid_cents          :integer          default(0)
#  check_in                   :date             not null
#  check_out                  :date             not null
#  cleaning_fee_cents         :integer          not null
#  company_name               :string
#  confirmation_number        :string           not null
#  deposit_amount_cents       :integer          not null
#  guest_email                :string           not null
#  guest_name                 :string           not null
#  guest_phone                :string
#  nightly_rate_cents         :integer          not null
#  num_guests                 :integer          not null
#  num_nights                 :integer          not null
#  retreat_type               :string
#  special_requests           :text
#  status                     :integer          default("pending"), not null
#  subtotal_cents             :integer          not null
#  taxes_cents                :integer          not null
#  total_cents                :integer          not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  property_id                :bigint           not null
#  stripe_checkout_session_id :string
#  stripe_payment_intent_id   :string
#
# Indexes
#
#  index_bookings_on_confirmation_number         (confirmation_number) UNIQUE
#  index_bookings_on_property_id                 (property_id)
#  index_bookings_on_stripe_checkout_session_id  (stripe_checkout_session_id)
#
# Foreign Keys
#
#  fk_rails_...  (property_id => properties.id)
#
require "rails_helper"

RSpec.describe Booking, type: :model do
  let(:property) { FactoryBot.create(:property) }

  describe "associations" do
    it { should belong_to(:property) }
    it { should have_many(:availabilities).dependent(:nullify) }
  end

  describe "validations" do
    subject { FactoryBot.build(:booking, property: property) }

    it { should validate_presence_of(:confirmation_number) }
    it { should validate_uniqueness_of(:confirmation_number) }
    it { should validate_presence_of(:check_in) }
    it { should validate_presence_of(:check_out) }
    it { should validate_presence_of(:num_guests) }
    it { should validate_numericality_of(:num_guests).is_greater_than(0) }
    it { should validate_presence_of(:guest_name) }
    it { should validate_presence_of(:guest_email) }
    it { should validate_presence_of(:guest_phone) }
    it { should validate_presence_of(:num_nights) }
    it { should validate_numericality_of(:num_nights).is_greater_than(0) }
    it { should validate_presence_of(:nightly_rate_cents) }
    it { should validate_numericality_of(:nightly_rate_cents).is_greater_than(0) }
    it { should validate_presence_of(:subtotal_cents) }
    it { should validate_numericality_of(:subtotal_cents).is_greater_than(0) }
    it { should validate_presence_of(:total_cents) }
    it { should validate_numericality_of(:total_cents).is_greater_than(0) }
    it { should validate_presence_of(:deposit_amount_cents) }
    it { should validate_numericality_of(:deposit_amount_cents).is_greater_than(0) }

    it "validates guest_email format" do
      should allow_value("test@example.com").for(:guest_email)
      should_not allow_value("invalid").for(:guest_email)
    end

    it "validates check_out is after check_in" do
      booking = FactoryBot.build(:booking, property: property,
                      check_in: Date.current + 5.days,
                      check_out: Date.current + 3.days)
      expect(booking).not_to be_valid
      expect(booking.errors[:check_out]).to be_present
    end
  end

  describe "enums" do
    it "defines status enum" do
      should define_enum_for(:status)
        .with_values(pending: 0, deposit_paid: 1, fully_paid: 2, confirmed: 3,
                     checked_in: 4, completed: 5, cancelled: 6, refunded: 7)
    end
  end

  describe "scopes" do
    let!(:past_booking) do
      FactoryBot.create(:booking, property: property,
             check_in: Date.current - 10.days, check_out: Date.current - 7.days)
    end
    let!(:upcoming_booking) do
      FactoryBot.create(:booking, property: property,
             check_in: Date.current + 10.days, check_out: Date.current + 13.days)
    end
    let!(:current_booking) do
      FactoryBot.create(:booking, property: property,
             check_in: Date.current - 1.day, check_out: Date.current + 2.days)
    end

    it "upcoming scope returns future bookings" do
      expect(Booking.upcoming).to include(upcoming_booking)
      expect(Booking.upcoming).not_to include(past_booking)
    end

    it "past scope returns past bookings" do
      expect(Booking.past).to include(past_booking)
      expect(Booking.past).not_to include(upcoming_booking)
    end

    it "current scope returns current bookings" do
      expect(Booking.current).to include(current_booking)
      expect(Booking.current).not_to include(past_booking)
    end
  end

  describe "#balance_due_cents" do
    it "returns the remaining balance" do
      booking = FactoryBot.build(:booking, property: property, total_cents: 500_000, amount_paid_cents: 125_000)
      expect(booking.balance_due_cents).to eq(375_000)
    end
  end

  describe "#confirm!" do
    it "updates status to confirmed" do
      booking = FactoryBot.create(:booking, property: property, status: :pending)
      booking.confirm!
      expect(booking.reload.status).to eq("confirmed")
    end
  end

  describe "#cancel!" do
    it "updates status to cancelled" do
      booking = FactoryBot.create(:booking, property: property, status: :pending)
      booking.cancel!
      expect(booking.reload.status).to eq("cancelled")
    end
  end
end

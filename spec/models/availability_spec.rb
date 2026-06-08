# == Schema Information
#
# Table name: availabilities
#
#  id                   :bigint           not null, primary key
#  date                 :date             not null
#  price_override_cents :integer
#  status               :integer          default("available"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  booking_id           :integer
#  property_id          :bigint           not null
#
# Indexes
#
#  index_availabilities_on_property_id           (property_id)
#  index_availabilities_on_property_id_and_date  (property_id,date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (property_id => properties.id)
#
require "rails_helper"

RSpec.describe Availability, type: :model do
  let(:property) { FactoryBot.create(:property) }

  describe "associations" do
    it { should belong_to(:property) }
    it { should belong_to(:booking).optional }
  end

  describe "validations" do
    subject { FactoryBot.build(:availability, property: property) }
    it { should validate_presence_of(:date) }
    it { should validate_uniqueness_of(:date).scoped_to(:property_id) }
  end

  describe "enums" do
    it "defines status enum" do
      should define_enum_for(:status)
        .with_values(available: 0, booked: 1, blocked: 2, maintenance: 3)
    end
  end

  describe "scopes" do
    let!(:avail1) { FactoryBot.create(:availability, property: property, date: Date.current + 10.days) }
    let!(:avail2) { FactoryBot.create(:availability, property: property, date: Date.current + 15.days) }
    let!(:avail3) { FactoryBot.create(:availability, property: property, date: Date.current + 20.days, status: :booked) }

    it "ordered scope sorts by date ascending" do
      expect(property.availabilities.ordered).to eq([avail1, avail2, avail3])
    end

    it "for_range scope filters by date range" do
      dates = Availability.for_range(Date.current + 12.days, Date.current + 18.days)
      expect(dates).to contain_exactly(avail2)
    end

    it "open scope returns only available dates" do
      expect(Availability.open).to include(avail1, avail2)
      expect(Availability.open).not_to include(avail3)
    end
  end
end

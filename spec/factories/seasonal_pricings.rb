# == Schema Information
#
# Table name: seasonal_pricings
#
#  id                    :bigint           not null, primary key
#  end_date              :date             not null
#  min_nights            :integer
#  name                  :string           not null
#  price_per_night_cents :integer          not null
#  start_date            :date             not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  property_id           :bigint           not null
#
# Indexes
#
#  index_seasonal_pricings_on_property_id  (property_id)
#
# Foreign Keys
#
#  fk_rails_...  (property_id => properties.id)
#
FactoryBot.define do
  factory :seasonal_pricing do
    property
    name { "Peak Season" }
    start_date { Date.current + 45.days }
    end_date { Date.current + 75.days }
    price_per_night_cents { 250_000 }
    min_nights { nil }
  end
end

# == Schema Information
#
# Table name: properties
#
#  id                 :bigint           not null, primary key
#  address            :string
#  base_price_cents   :integer          not null
#  bathrooms          :integer          not null
#  bedrooms           :integer          not null
#  check_in_time      :string           default("3:00 PM")
#  check_out_time     :string           default("11:00 AM")
#  city               :string
#  cleaning_fee_cents :integer          default(0), not null
#  deposit_percentage :integer          default(25)
#  description        :text
#  latitude           :decimal(10, 7)
#  longitude          :decimal(10, 7)
#  max_guests         :integer          not null
#  max_nights         :integer          default(30)
#  min_nights         :integer          default(2)
#  name               :string           not null
#  short_description  :string
#  square_feet        :integer
#  state              :string           default("CO")
#  tagline            :string
#  zip                :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
FactoryBot.define do
  factory :property do
    name { "The Anchorpoint Retreat" }
    tagline { "Find Your Anchor in the Colorado Rockies" }
    description { "A beautiful mountain retreat in Colorado." }
    short_description { "A private mountain sanctuary." }
    address { "123 Mountain Vista Drive" }
    city { "Telluride" }
    state { "CO" }
    zip { "81435" }
    latitude { 37.9375 }
    longitude { -107.8459 }
    bedrooms { 6 }
    bathrooms { 5 }
    max_guests { 16 }
    square_feet { 4200 }
    base_price_cents { 150_000 }
    cleaning_fee_cents { 35_000 }
    deposit_percentage { 25 }
    min_nights { 2 }
    max_nights { 30 }
    check_in_time { "3:00 PM" }
    check_out_time { "11:00 AM" }
  end
end

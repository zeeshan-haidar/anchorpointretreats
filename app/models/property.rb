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
class Property < ApplicationRecord
  has_many :property_images, dependent: :destroy
  has_many :amenities, dependent: :destroy
  has_many :seasonal_pricings, dependent: :destroy
  has_many :availabilities, dependent: :destroy
  has_many :bookings, dependent: :destroy

  validates :name, presence: true
  validates :bedrooms, presence: true, numericality: { greater_than: 0 }
  validates :bathrooms, presence: true, numericality: { greater_than: 0 }
  validates :max_guests, presence: true, numericality: { greater_than: 0 }
  validates :base_price_cents, presence: true, numericality: { greater_than: 0 }
  validates :cleaning_fee_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :deposit_percentage, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :min_nights, numericality: { greater_than: 0 }
  validates :max_nights, numericality: { greater_than: 0 }

  scope :active, -> { where.not(name: nil) }
end

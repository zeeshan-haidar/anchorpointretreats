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
class SeasonalPricing < ApplicationRecord
  belongs_to :property

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :price_per_night_cents, presence: true, numericality: { greater_than: 0 }
  validates :min_nights, numericality: { greater_than: 0 }, allow_nil: true

  scope :current, -> { where('start_date <= ? AND end_date >= ?', Date.current, Date.current) }
  scope :upcoming, -> { where('start_date > ?', Date.current).order(start_date: :asc) }
  scope :ordered, -> { order(start_date: :asc) }
end

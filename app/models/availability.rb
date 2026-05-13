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
class Availability < ApplicationRecord
  belongs_to :property
  belongs_to :booking, optional: true

  enum :status, { available: 0, booked: 1, blocked: 2, maintenance: 3 }

  validates :date, presence: true
  validates :date, uniqueness: { scope: :property_id }

  scope :ordered, -> { order(date: :asc) }
  scope :for_range, ->(start_date, end_date) { where(date: start_date...end_date) }
  scope :open, -> { where(status: :available) }
end

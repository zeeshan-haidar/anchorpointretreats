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
FactoryBot.define do
  factory :availability do
    property
    date { Date.current + 30.days }
    status { :available }
  end
end

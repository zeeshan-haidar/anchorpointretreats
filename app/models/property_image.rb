# == Schema Information
#
# Table name: property_images
#
#  id          :bigint           not null, primary key
#  alt_text    :string
#  caption     :string
#  category    :integer          default("hero"), not null
#  sort_order  :integer          default(0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  property_id :bigint           not null
#
# Indexes
#
#  index_property_images_on_property_id  (property_id)
#
# Foreign Keys
#
#  fk_rails_...  (property_id => properties.id)
#
class PropertyImage < ApplicationRecord
  belongs_to :property

  enum :category, {
    hero: 0, exterior: 1, interior: 2, bedroom: 3, bathroom: 4,
    kitchen: 5, living: 6, outdoor: 7, amenity: 8, aerial: 9
  }

  validates :category, presence: true

  scope :ordered, -> { order(sort_order: :asc) }
  scope :featured, -> { where(category: :hero) }
end

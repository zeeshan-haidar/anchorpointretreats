# == Schema Information
#
# Table name: amenities
#
#  id          :bigint           not null, primary key
#  category    :integer          default("wellness"), not null
#  description :string
#  featured    :boolean          default(FALSE)
#  icon        :string
#  name        :string           not null
#  sort_order  :integer          default(0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  property_id :bigint           not null
#
# Indexes
#
#  index_amenities_on_property_id  (property_id)
#
# Foreign Keys
#
#  fk_rails_...  (property_id => properties.id)
#
class Amenity < ApplicationRecord
  belongs_to :property

  enum :category, { wellness: 0, outdoor: 1, kitchen: 2, comfort: 3, workspace: 4, entertainment: 5, safety: 6 }

  validates :name, presence: true
  validates :category, presence: true

  scope :ordered, -> { order(sort_order: :asc) }
  scope :featured, -> { where(featured: true) }
end

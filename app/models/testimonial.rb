# == Schema Information
#
# Table name: testimonials
#
#  id           :bigint           not null, primary key
#  author_name  :string           not null
#  author_title :string
#  content      :text             not null
#  featured     :boolean          default(FALSE)
#  rating       :integer          default(5)
#  retreat_type :string
#  sort_order   :integer          default(0)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Testimonial < ApplicationRecord
  validates :author_name, presence: true
  validates :content, presence: true
  validates :rating, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }

  scope :ordered, -> { order(sort_order: :asc) }
  scope :featured, -> { where(featured: true) }
end

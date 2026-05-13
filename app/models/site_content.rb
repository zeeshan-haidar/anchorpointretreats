# == Schema Information
#
# Table name: site_contents
#
#  id           :bigint           not null, primary key
#  content_type :integer          default("text")
#  key          :string           not null
#  value        :text             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_site_contents_on_key  (key) UNIQUE
#
class SiteContent < ApplicationRecord
  enum :content_type, { text: 0, html: 1, url: 2, json: 3 }

  validates :key, presence: true, uniqueness: true
  validates :value, presence: true
end

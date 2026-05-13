# == Schema Information
#
# Table name: inquiries
#
#  id              :bigint           not null, primary key
#  admin_notes     :text
#  company         :string
#  email           :string           not null
#  group_size      :integer
#  message         :text             not null
#  name            :string           not null
#  phone           :string
#  preferred_dates :string
#  retreat_type    :string
#  status          :integer          default("new_inquiry"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Inquiry < ApplicationRecord
  enum :status, { new_inquiry: 0, responded: 1, closed: 2 }

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true

  scope :newest_first, -> { order(created_at: :desc) }
  scope :unread, -> { where(status: :new_inquiry) }
end

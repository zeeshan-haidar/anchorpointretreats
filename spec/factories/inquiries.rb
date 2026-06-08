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
FactoryBot.define do
  factory :inquiry do
    name { "Jane Smith" }
    email { "jane@example.com" }
    phone { "(555) 987-6543" }
    company { "Wellness Co." }
    retreat_type { "wellness" }
    preferred_dates { "August 2026" }
    group_size { 8 }
    message { "We're interested in booking a wellness retreat." }
    status { :new_inquiry }
  end
end

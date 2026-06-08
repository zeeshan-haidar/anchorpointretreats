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
require "rails_helper"

RSpec.describe Inquiry, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:message) }

    it "validates email format" do
      should allow_value("test@example.com").for(:email)
      should_not allow_value("invalid").for(:email)
    end
  end

  describe "enums" do
    it "defines status enum" do
      should define_enum_for(:status)
        .with_values(new_inquiry: 0, responded: 1, closed: 2)
    end
  end

  describe "scopes" do
    let!(:inquiry1) { FactoryBot.create(:inquiry, created_at: 2.days.ago) }
    let!(:inquiry2) { FactoryBot.create(:inquiry, created_at: 1.day.ago, status: :responded) }

    it "newest_first scope orders by created_at descending" do
      expect(Inquiry.newest_first).to eq([inquiry2, inquiry1])
    end

    it "unread scope returns only new inquiries" do
      expect(Inquiry.unread).to include(inquiry1)
      expect(Inquiry.unread).not_to include(inquiry2)
    end
  end
end

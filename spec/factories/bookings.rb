# == Schema Information
#
# Table name: bookings
#
#  id                         :bigint           not null, primary key
#  admin_notes                :text
#  amount_paid_cents          :integer          default(0)
#  check_in                   :date             not null
#  check_out                  :date             not null
#  cleaning_fee_cents         :integer          not null
#  company_name               :string
#  confirmation_number        :string           not null
#  deposit_amount_cents       :integer          not null
#  guest_email                :string           not null
#  guest_name                 :string           not null
#  guest_phone                :string
#  nightly_rate_cents         :integer          not null
#  num_guests                 :integer          not null
#  num_nights                 :integer          not null
#  retreat_type               :string
#  special_requests           :text
#  status                     :integer          default("pending"), not null
#  subtotal_cents             :integer          not null
#  taxes_cents                :integer          not null
#  total_cents                :integer          not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  property_id                :bigint           not null
#  stripe_checkout_session_id :string
#  stripe_payment_intent_id   :string
#
# Indexes
#
#  index_bookings_on_confirmation_number         (confirmation_number) UNIQUE
#  index_bookings_on_property_id                 (property_id)
#  index_bookings_on_stripe_checkout_session_id  (stripe_checkout_session_id)
#
# Foreign Keys
#
#  fk_rails_...  (property_id => properties.id)
#
FactoryBot.define do
  factory :booking do
    property
    confirmation_number { "AP-#{Date.current.strftime('%Y%m%d')}-#{SecureRandom.alphanumeric(4).upcase}" }
    check_in { Date.current + 60.days }
    check_out { Date.current + 63.days }
    num_guests { 4 }
    guest_name { "John Doe" }
    guest_email { "john@example.com" }
    guest_phone { "(555) 123-4567" }
    company_name { "Acme Corp" }
    retreat_type { "corporate" }
    special_requests { "Looking for a great experience." }
    num_nights { 3 }
    nightly_rate_cents { 150_000 }
    subtotal_cents { 450_000 }
    cleaning_fee_cents { 35_000 }
    taxes_cents { 41_225 }
    total_cents { 526_225 }
    deposit_amount_cents { 131_556 }
    amount_paid_cents { 0 }
    status { :pending }
  end
end

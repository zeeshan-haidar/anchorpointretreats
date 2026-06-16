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
class Booking < ApplicationRecord
  belongs_to :property
  has_many :availabilities, dependent: :nullify

  enum :status, {
    pending: 0, deposit_paid: 1, fully_paid: 2, confirmed: 3,
    checked_in: 4, completed: 5, cancelled: 6, refunded: 7
  }

  validates :confirmation_number, presence: true, uniqueness: true
  validates :check_in, presence: true
  validates :check_out, presence: true
  validates :num_guests, presence: true, numericality: { greater_than: 0 }
  validates :guest_name, presence: true
  validates :guest_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :guest_phone, presence: true
  validates :num_nights, presence: true, numericality: { greater_than: 0 }
  validates :nightly_rate_cents, presence: true, numericality: { greater_than: 0 }
  validates :subtotal_cents, presence: true, numericality: { greater_than: 0 }
  validates :cleaning_fee_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :taxes_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :total_cents, presence: true, numericality: { greater_than: 0 }
  validates :deposit_amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :amount_paid_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :check_out, comparison: { greater_than: :check_in }

  scope :upcoming, -> { where('check_in > ?', Date.current).order(check_in: :asc) }
  scope :current, -> { where('check_in <= ? AND check_out >= ?', Date.current, Date.current) }
  scope :past, -> { where(check_out: ...Date.current).order(check_out: :desc) }
  scope :by_date_range, ->(start_date, end_date) { where(check_in: start_date...end_date) }
  scope :search_by_guest, ->(query) { where('guest_name ILIKE :q OR guest_email ILIKE :q', q: "%#{query}%") }

  def confirm!
    update!(status: :confirmed)
  end

  def cancel!
    update!(status: :cancelled)
  end

  def balance_due_cents
    total_cents - amount_paid_cents
  end

  # Syncs booking status with Stripe if the webhook may have been missed.
  # Useful as a fallback on the confirmation page, or to run in console.
  # Also marks availability dates as booked (same as the webhook does).
  # Returns true if the booking was updated, false otherwise.
  def sync_with_stripe!
    return false unless stripe_checkout_session_id.present?
    return false unless pending?

    session = Stripe::Checkout::Session.retrieve(stripe_checkout_session_id)
    return false unless session.payment_status == "paid"

    ActiveRecord::Base.transaction do
      update!(
        status: :fully_paid,
        amount_paid_cents: session.amount_total,
        stripe_payment_intent_id: session.payment_intent
      )

      # Mark availability dates as booked
      AvailabilityService.new(property).mark_booked(
        check_in: check_in,
        check_out: check_out,
        booking: self
      )
    end

    BookingMailer.confirmation(self).deliver_later

    true
  rescue Stripe::StripeError => e
    Rails.logger.warn "[Booking##{id}] Stripe sync failed: #{e.message}"
    false
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn "[Booking##{id}] Stripe sync succeeded but failed to mark availability: #{e.message}"
    false
  end
end

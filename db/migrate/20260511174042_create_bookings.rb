class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      t.references :property, null: false, foreign_key: true
      t.string :confirmation_number, null: false
      t.date :check_in, null: false
      t.date :check_out, null: false
      t.integer :num_guests, null: false
      t.string :guest_name, null: false
      t.string :guest_email, null: false
      t.string :guest_phone
      t.string :company_name
      t.string :retreat_type
      t.text :special_requests
      t.integer :num_nights, null: false
      t.integer :nightly_rate_cents, null: false
      t.integer :subtotal_cents, null: false
      t.integer :cleaning_fee_cents, null: false
      t.integer :taxes_cents, null: false
      t.integer :total_cents, null: false
      t.integer :deposit_amount_cents, null: false
      t.integer :amount_paid_cents, default: 0
      t.integer :status, null: false, default: 0
      t.string :stripe_checkout_session_id
      t.string :stripe_payment_intent_id
      t.text :admin_notes

      t.timestamps
    end

    add_index :bookings, :confirmation_number, unique: true
    add_index :bookings, :stripe_checkout_session_id
  end
end

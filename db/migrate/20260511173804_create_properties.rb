class CreateProperties < ActiveRecord::Migration[7.1]
  def change
    create_table :properties do |t|
      t.string :name, null: false
      t.string :tagline
      t.text :description
      t.string :short_description
      t.string :address
      t.string :city
      t.string :state, default: "CO"
      t.string :zip
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.integer :bedrooms, null: false
      t.integer :bathrooms, null: false
      t.integer :max_guests, null: false
      t.integer :square_feet
      t.integer :base_price_cents, null: false
      t.integer :cleaning_fee_cents, default: 0, null: false
      t.integer :deposit_percentage, default: 25
      t.integer :min_nights, default: 2
      t.integer :max_nights, default: 30
      t.string :check_in_time, default: "3:00 PM"
      t.string :check_out_time, default: "11:00 AM"

      t.timestamps
    end
  end
end

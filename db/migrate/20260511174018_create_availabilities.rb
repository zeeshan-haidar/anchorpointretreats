class CreateAvailabilities < ActiveRecord::Migration[7.1]
  def change
    create_table :availabilities do |t|
      t.references :property, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :status, null: false, default: 0
      t.integer :booking_id
      t.integer :price_override_cents

      t.timestamps
      t.index [:property_id, :date], unique: true
    end
  end
end

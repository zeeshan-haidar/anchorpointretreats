class CreateSeasonalPricings < ActiveRecord::Migration[7.1]
  def change
    create_table :seasonal_pricings do |t|
      t.references :property, null: false, foreign_key: true
      t.string :name, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :price_per_night_cents, null: false
      t.integer :min_nights

      t.timestamps
    end
  end
end

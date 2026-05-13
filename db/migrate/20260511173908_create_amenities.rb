class CreateAmenities < ActiveRecord::Migration[7.1]
  def change
    create_table :amenities do |t|
      t.references :property, null: false, foreign_key: true
      t.string :name, null: false
      t.string :description
      t.string :icon
      t.integer :category, null: false, default: 0
      t.integer :sort_order, default: 0
      t.boolean :featured, default: false

      t.timestamps
    end
  end
end

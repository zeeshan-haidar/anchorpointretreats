class CreatePropertyImages < ActiveRecord::Migration[7.1]
  def change
    create_table :property_images do |t|
      t.references :property, null: false, foreign_key: true
      t.string :alt_text
      t.string :caption
      t.integer :category, null: false, default: 0
      t.integer :sort_order, default: 0

      t.timestamps
    end
  end
end

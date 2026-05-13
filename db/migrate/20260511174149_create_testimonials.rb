class CreateTestimonials < ActiveRecord::Migration[7.1]
  def change
    create_table :testimonials do |t|
      t.string :author_name, null: false
      t.string :author_title
      t.text :content, null: false
      t.integer :rating, default: 5
      t.string :retreat_type
      t.boolean :featured, default: false
      t.integer :sort_order, default: 0

      t.timestamps
    end
  end
end

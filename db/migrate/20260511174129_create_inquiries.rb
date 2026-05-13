class CreateInquiries < ActiveRecord::Migration[7.1]
  def change
    create_table :inquiries do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :company
      t.string :retreat_type
      t.string :preferred_dates
      t.integer :group_size
      t.text :message, null: false
      t.integer :status, null: false, default: 0
      t.text :admin_notes

      t.timestamps
    end
  end
end

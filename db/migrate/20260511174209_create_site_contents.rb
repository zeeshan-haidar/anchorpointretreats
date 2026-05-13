class CreateSiteContents < ActiveRecord::Migration[7.1]
  def change
    create_table :site_contents do |t|
      t.string :key, null: false
      t.text :value, null: false
      t.integer :content_type, default: 0

      t.timestamps
    end

    add_index :site_contents, :key, unique: true
  end
end

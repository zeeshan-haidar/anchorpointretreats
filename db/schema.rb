# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_05_11_174209) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "name", null: false
    t.integer "role", default: 0, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "amenities", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.string "name", null: false
    t.string "description"
    t.string "icon"
    t.integer "category", default: 0, null: false
    t.integer "sort_order", default: 0
    t.boolean "featured", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_amenities_on_property_id"
  end

  create_table "availabilities", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.date "date", null: false
    t.integer "status", default: 0, null: false
    t.integer "booking_id"
    t.integer "price_override_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id", "date"], name: "index_availabilities_on_property_id_and_date", unique: true
    t.index ["property_id"], name: "index_availabilities_on_property_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.string "confirmation_number", null: false
    t.date "check_in", null: false
    t.date "check_out", null: false
    t.integer "num_guests", null: false
    t.string "guest_name", null: false
    t.string "guest_email", null: false
    t.string "guest_phone"
    t.string "company_name"
    t.string "retreat_type"
    t.text "special_requests"
    t.integer "num_nights", null: false
    t.integer "nightly_rate_cents", null: false
    t.integer "subtotal_cents", null: false
    t.integer "cleaning_fee_cents", null: false
    t.integer "taxes_cents", null: false
    t.integer "total_cents", null: false
    t.integer "deposit_amount_cents", null: false
    t.integer "amount_paid_cents", default: 0
    t.integer "status", default: 0, null: false
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.text "admin_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_number"], name: "index_bookings_on_confirmation_number", unique: true
    t.index ["property_id"], name: "index_bookings_on_property_id"
    t.index ["stripe_checkout_session_id"], name: "index_bookings_on_stripe_checkout_session_id"
  end

  create_table "inquiries", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone"
    t.string "company"
    t.string "retreat_type"
    t.string "preferred_dates"
    t.integer "group_size"
    t.text "message", null: false
    t.integer "status", default: 0, null: false
    t.text "admin_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "properties", force: :cascade do |t|
    t.string "name", null: false
    t.string "tagline"
    t.text "description"
    t.string "short_description"
    t.string "address"
    t.string "city"
    t.string "state", default: "CO"
    t.string "zip"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.integer "bedrooms", null: false
    t.integer "bathrooms", null: false
    t.integer "max_guests", null: false
    t.integer "square_feet"
    t.integer "base_price_cents", null: false
    t.integer "cleaning_fee_cents", default: 0, null: false
    t.integer "deposit_percentage", default: 25
    t.integer "min_nights", default: 2
    t.integer "max_nights", default: 30
    t.string "check_in_time", default: "3:00 PM"
    t.string "check_out_time", default: "11:00 AM"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "property_images", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.string "alt_text"
    t.string "caption"
    t.integer "category", default: 0, null: false
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_property_images_on_property_id"
  end

  create_table "seasonal_pricings", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.string "name", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "price_per_night_cents", null: false
    t.integer "min_nights"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_seasonal_pricings_on_property_id"
  end

  create_table "site_contents", force: :cascade do |t|
    t.string "key", null: false
    t.text "value", null: false
    t.integer "content_type", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_site_contents_on_key", unique: true
  end

  create_table "testimonials", force: :cascade do |t|
    t.string "author_name", null: false
    t.string "author_title"
    t.text "content", null: false
    t.integer "rating", default: 5
    t.string "retreat_type"
    t.boolean "featured", default: false
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "amenities", "properties"
  add_foreign_key "availabilities", "properties"
  add_foreign_key "bookings", "properties"
  add_foreign_key "property_images", "properties"
  add_foreign_key "seasonal_pricings", "properties"
end

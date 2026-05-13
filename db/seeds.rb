# db/seeds.rb
#
# Seeds the database with realistic data for The Anchorpoint Retreat.
#
# Usage:
#   bin/rails db:seed
#   bin/rails db:seed:replant  # wipe + reseed

puts "🌱 Seeding database..."

# ──────────────────────────────────────────────
# Admin User
# ──────────────────────────────────────────────
admin = AdminUser.find_or_create_by!(email: "admin@anchorpointretreat.com") do |u|
  u.name = "Property Manager"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :super_admin
end
puts "  ✓ Admin user: #{admin.email}"

# ──────────────────────────────────────────────
# Property
# ──────────────────────────────────────────────
property = Property.find_or_create_by!(name: "The Anchorpoint Retreat") do |p|
  p.tagline = "Find Your Anchor in the Colorado Rockies"
  p.short_description = "A private mountain sanctuary in Colorado for corporate retreats, wellness getaways, and private gatherings."
  p.description = <<~DESC
    Nestled in the heart of the Colorado Rockies, The Anchorpoint Retreat offers a seamless blend of rustic charm and modern luxury. With panoramic mountain views, expansive indoor-outdoor living spaces, and world-class amenities, it's the ideal setting for corporate retreats, wellness getaways, and private celebrations.

    The 4,200 square foot lodge combines modern luxury with mountain rustic charm, featuring floor-to-ceiling windows, reclaimed wood accents, and stone fireplaces. Every detail has been thoughtfully designed to create an environment where guests can reconnect — with nature, with each other, and with themselves.

    Whether you're planning a corporate offsite, a wellness retreat, or a family gathering, the property provides the perfect balance of shared spaces for connection and private nooks for quiet reflection.
  DESC
  p.address = "123 Mountain Vista Drive"
  p.city = "Telluride"
  p.state = "CO"
  p.zip = "81435"
  p.latitude = 37.9375
  p.longitude = -107.8459
  p.bedrooms = 6
  p.bathrooms = 5
  p.max_guests = 16
  p.square_feet = 4200
  p.base_price_cents = 150_000  # $1,500/night
  p.cleaning_fee_cents = 35_000 # $350
  p.deposit_percentage = 25
  p.min_nights = 2
  p.max_nights = 30
  p.check_in_time = "3:00 PM"
  p.check_out_time = "11:00 AM"
end
puts "  ✓ Property: #{property.name}"

# ──────────────────────────────────────────────
# Amenities
# ──────────────────────────────────────────────
amenities_data = [
  { name: "Private Hot Tub", description: "Soak under the stars after a day on the slopes", icon: "fa-solid fa-hot-tub", category: :wellness, featured: true },
  { name: "Sauna", description: "Infrared sauna for deep relaxation", icon: "fa-solid fa-temperature-high", category: :wellness, featured: true },
  { name: "Yoga Deck", description: "Sunrise yoga with panoramic mountain views", icon: "fa-solid fa-person-praying", category: :wellness, featured: true },
  { name: "Fire Pit", description: "Evening stories and s'mores under the stars", icon: "fa-solid fa-fire", category: :outdoor, featured: true },
  { name: "Hiking Trails", description: "3 miles of private trails on the property", icon: "fa-solid fa-person-hiking", category: :outdoor, featured: true },
  { name: "Outdoor Dining", description: "Terrace seating for 16 with mountain views", icon: "fa-solid fa-utensils", category: :outdoor, featured: false },
  { name: "Gourmet Kitchen", description: "Chef-grade appliances and dual ovens", icon: "fa-solid fa-kitchen-set", category: :kitchen, featured: true },
  { name: "Wine Refrigerator", description: "Climate-controlled wine storage", icon: "fa-solid fa-wine-glass-alt", category: :kitchen, featured: false },
  { name: "Espresso Machine", description: "Professional-grade espresso and cappuccino", icon: "fa-solid fa-mug-hot", category: :kitchen, featured: false },
  { name: "Riverstone Fireplace", description: "Great room fireplace with 20-ft ceilings", icon: "fa-solid fa-fire", category: :comfort, featured: true },
  { name: "Radiant Heating", description: "In-floor radiant heating throughout", icon: "fa-solid fa-temperature-high", category: :comfort, featured: false },
  { name: "Luxury Linens", description: "Premium Frette linens and towels", icon: "fa-solid fa-bed", category: :comfort, featured: false },
  { name: "High-Speed WiFi", description: "Starlink gigabit internet", icon: "fa-solid fa-wifi", category: :workspace, featured: true },
  { name: "Meeting Room", description: "Dedicated space with smart conferencing", icon: "fa-solid fa-laptop", category: :workspace, featured: true },
  { name: "Smart TVs", description: "65-inch smart TVs in living areas and bedrooms", icon: "fa-solid fa-tv", category: :entertainment, featured: false },
  { name: "Board Games", description: "Curated selection of board games and puzzles", icon: "fa-solid fa-gamepad", category: :entertainment, featured: false },
  { name: "First Aid Kit", description: "Fully stocked first aid and emergency supplies", icon: "fa-solid fa-kit-medical", category: :safety, featured: false },
  { name: "Emergency Generator", description: "Whole-property backup generator", icon: "fa-solid fa-bolt", category: :safety, featured: false },
]

amenities_data.each_with_index do |attrs, idx|
  property.amenities.find_or_create_by!(name: attrs[:name]) do |a|
    a.description = attrs[:description]
    a.icon = attrs[:icon]
    a.category = attrs[:category]
    a.featured = attrs[:featured]
    a.sort_order = idx
  end
end
puts "  ✓ #{amenities_data.size} amenities"

# ──────────────────────────────────────────────
# Seasonal Pricing
# ──────────────────────────────────────────────
seasonal_pricings_data = [
  { name: "Peak Ski Season", start_date: "2026-12-15", end_date: "2027-03-15", price_per_night_cents: 250_000, min_nights: 3 },
  { name: "Summer Peak", start_date: "2026-06-01", end_date: "2026-09-15", price_per_night_cents: 200_000, min_nights: 2 },
  { name: "Fall Colors", start_date: "2026-09-16", end_date: "2026-10-31", price_per_night_cents: 180_000, min_nights: 2 },
  { name: "Holiday", start_date: "2026-12-20", end_date: "2027-01-05", price_per_night_cents: 350_000, min_nights: 4 },
]

seasonal_pricings_data.each do |attrs|
  property.seasonal_pricings.find_or_create_by!(name: attrs[:name]) do |s|
    s.start_date = Date.parse(attrs[:start_date])
    s.end_date = Date.parse(attrs[:end_date])
    s.price_per_night_cents = attrs[:price_per_night_cents]
    s.min_nights = attrs[:min_nights]
  end
end
puts "  ✓ #{seasonal_pricings_data.size} seasonal pricings"

# ──────────────────────────────────────────────
# Availability (next 12 months: all available initially)
# ──────────────────────────────────────────────
start_date = Date.current
end_date = start_date + 365.days

existing_dates = property.availabilities.pluck(:date)
dates_to_create = (start_date..end_date).reject { |d| existing_dates.include?(d) }

dates_to_create.each_slice(100) do |batch|
  records = batch.map do |date|
    { property_id: property.id, date: date, status: 0, created_at: Time.current, updated_at: Time.current }
  end
  Availability.insert_all(records)
end
puts "  ✓ #{dates_to_create.size} availability dates generated"

# ──────────────────────────────────────────────
# Testimonials
# ──────────────────────────────────────────────
testimonials_data = [
  { author_name: "Sarah Mitchell", author_title: "CEO, TechVentures Inc.",
    content: "The Anchorpoint Retreat exceeded every expectation. Our team left feeling refreshed, inspired, and closer than ever. The setting is absolutely magical — we're already planning our next retreat.",
    rating: 5, featured: true },
  { author_name: "James Rodriguez", author_title: "Wellness Coach",
    content: "A truly transformative experience. The wellness amenities, the quiet surroundings, and the attentive hosting made our yoga retreat unforgettable. The morning yoga sessions on the deck were pure magic.",
    rating: 5, featured: true },
  { author_name: "The Parker Family", author_title: "Annual Family Retreat",
    content: "We hosted our family reunion here and it was perfect. The large kitchen, the fire pit, the hiking trails — every detail was thoughtfully designed. The kids didn't want to leave!",
    rating: 5, featured: true },
  { author_name: "Michael Chen", author_title: "VP Engineering, DataFlow",
    content: "Best corporate offsite we've ever had. The combination of meeting spaces and outdoor activities created the perfect environment for both productive sessions and team bonding.",
    rating: 5, featured: false },
  { author_name: "Emma Williams", author_title: "Yoga Instructor",
    content: "The property is a wellness dream. From the yoga deck to the sauna to the healthy meal prep kitchen — everything you need for a world-class retreat is right here.",
    rating: 4, featured: false, retreat_type: "wellness" },
]

testimonials_data.each_with_index do |attrs, idx|
  Testimonial.find_or_create_by!(author_name: attrs[:author_name]) do |t|
    t.author_title = attrs[:author_title]
    t.content = attrs[:content]
    t.rating = attrs[:rating]
    t.featured = attrs[:featured]
    t.retreat_type = attrs[:retreat_type]
    t.sort_order = idx
  end
end
puts "  ✓ #{testimonials_data.size} testimonials"

# ──────────────────────────────────────────────
# Site Content
# ──────────────────────────────────────────────
site_contents_data = [
  { key: "hero_headline", value: "Find Your Anchor in the Colorado Rockies" },
  { key: "hero_subtitle", value: "Escape to a private mountain sanctuary where breathtaking views meet unparalleled comfort." },
  { key: "hero_cta_primary", value: "Check Availability" },
  { key: "hero_cta_secondary", value: "Take a Tour" },
  { key: "about_heading", value: "A Private Mountain Sanctuary" },
  { key: "about_text", value: "Nestled in the heart of the Colorado Rockies, The Anchorpoint Retreat offers a seamless blend of rustic charm and modern luxury." },
  { key: "metrics_retreats_hosted", value: "50" },
  { key: "metrics_guest_rating", value: "4.9" },
  { key: "metrics_max_guests", value: "16" },
  { key: "metrics_acreage", value: "10" },
  { key: "footer_tagline", value: "Subscribe for updates and special offers" },
  { key: "copyright_text", value: "© 2026 The Anchorpoint Retreat. All rights reserved." },
]

site_contents_data.each do |attrs|
  SiteContent.find_or_create_by!(key: attrs[:key]) do |sc|
    sc.value = attrs[:value]
  end
end
puts "  ✓ #{site_contents_data.size} site contents"

# ──────────────────────────────────────────────
puts "🌱 Done! #{AdminUser.count} admin, #{Property.count} property, #{Amenity.count} amenities, #{SeasonalPricing.count} seasonal pricings, #{Availability.count} availability dates, #{Testimonial.count} testimonials, #{SiteContent.count} site contents."

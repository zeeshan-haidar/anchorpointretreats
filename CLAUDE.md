# The Anchorpoint Retreat — Colorado Property Rental Website

## Project Overview
Single-property rental website for a corporate retreat / wellness property in Colorado. Guests can browse, check availability, book with Stripe payments, or submit inquiries. Admin panel for property management.

Structure and content inspired by [discoverwilder.com](https://discoverwilder.com/) — premium, nature-forward layout with clear information hierarchy, distinct pages and content sections. Use their text as a reference for tone, phrasing style, and section structure, but **always rewrite copy to be original** — never copy text verbatim. Adapt language to fit a Colorado mountain retreat context.

for design and style follow the included bootstrap template /html-template

## Tech Stack
- **Ruby** 3.3.8
- **Rails** 7.1 (Hotwire: Turbo + Stimulus)
- **PostgreSQL** for database
- **Bootstrap css** for styling
- **Devise** for authentication
- **CanCanCan** for authorization
- **Stripe** for payments (Checkout Sessions)
- **Sidekiq + Redis** for background jobs
- **Active Storage** for image uploads
- **importmap-rails** for JavaScript

## Commands
```bash
# Setup
bundle install
rails db:create db:migrate db:seed

# Dev server
bin/dev                          # runs Rails + Tailwind watcher via Procfile.dev

# Tests
bundle exec rspec                # run full test suite
bundle exec rspec spec/models    # run model specs only
bundle exec rspec spec/requests  # run request specs only

# Linting
bundle exec rubocop              # check all files
bundle exec rubocop -a           # auto-fix safe offenses
bundle exec rubocop -A           # auto-fix all offenses (including unsafe)

# Database
rails db:migrate
rails db:rollback
rails db:seed
rails console
bundle exec annotate         # add schema annotations to models

# Stripe webhook testing
stripe listen --forward-to localhost:3000/webhooks/stripe

# Background jobs
bundle exec sidekiq
```

## Project Structure
```
app/
  controllers/
    pages_controller.rb          # static pages (home, about, experience, faq, etc.)
    property_controller.rb       # property details page
    availability_controller.rb   # calendar + pricing API
    bookings_controller.rb       # booking flow
    inquiries_controller.rb      # inquiry form
    webhooks_controller.rb       # Stripe webhooks
    admin/
      base_controller.rb         # admin auth + layout base
      dashboard_controller.rb
      calendar_controller.rb     # availability management
      bookings_controller.rb
      inquiries_controller.rb
      property_controller.rb
      photos_controller.rb
      amenities_controller.rb
      seasonal_pricings_controller.rb
      testimonials_controller.rb
      content_controller.rb
      settings_controller.rb
  services/
    availability_service.rb
    pricing_service.rb
    booking_service.rb
    stripe_checkout_service.rb
    stripe_webhook_service.rb
    inquiry_service.rb
  javascript/controllers/        # Stimulus controllers
```

## Code Standards
- **DRY** — extract shared logic into concerns, service objects, or helpers. Do not repeat code.
- **RuboCop** — all code must pass `bundle exec rubocop` with zero offenses. Follow rubocop-rails, rubocop-rspec, and rubocop-performance rules.
- **Comments on controller actions** — every action must have a comment with HTTP method and route:
  ```ruby
  # GET /availability
  def index
    ...
  end

  # POST /book
  def create
    ...
  end
  ```
- **Comments on complex code** — add explanatory comments for non-obvious logic, business rules, tricky queries, or workarounds. Simple/self-explanatory code needs no comments.

## Key Conventions
- All prices stored in **cents** (integer) — never floats for money
- Enums use Rails enums on models (status fields, categories, roles)
- Service objects in `app/services/` for business logic
- Admin routes namespaced under `/admin` with `Admin::BaseController` parent
- Public booking flow: `/availability` -> `/book` -> `/book/:id/payment` -> `/book/:id/confirmation`
- Stripe webhook at `/webhooks/stripe` with signature verification
- RSpec request specs for controllers, model specs for validations/associations
- FactoryBot for test data, Faker for realistic values

## Design Tokens
- Primary (text/headings): Deep Espresso #312B24
- Secondary (background): Soft Sage #EAF0EA
- Muted (secondary text): Muted Gray #747474
- Accent (CTAs/links): Sage Green #64734F
- Dark overlay: Deep Green #1A312A
- Subtle border: Light Taupe #D6D1CC
- Headings: Lora (serif, weight 400)
- Body: Inter Tight (sans-serif, weight 400)
- Buttons/Links: Lora (serif, weight 400)
- Content max-width: 1440px

## Documentation
- Full SRS: `claude/docs/SRS.md`

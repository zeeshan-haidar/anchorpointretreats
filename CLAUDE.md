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
bin/dev                          # runs Rails + watcher via Procfile.dev

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

### General Principles
- **DRY** — extract shared logic into concerns, service objects, or helpers. Do not repeat code.
- **KISS** — prefer clarity over cleverness. Simple/self-explanatory code needs no comments.
- **RuboCop** — all code must pass `bundle exec rubocop` with zero offenses. Follow rubocop-rails, rubocop-rspec, and rubocop-performance rules.
- **Rails Conventions Over Configuration** — follow Rails community standards.

### Ruby Style
- Target Ruby version: **3.3.8**
- 2-space soft indentation
- Prefer double-quoted strings unless interpolation or special characters are needed
- Use `&&`/`||` over `and`/`or`
- Use `_` for unused block params: `users.each { |_name, role| ... }`
- Hash syntax: Prefer `{ key: value }` over `{ :key => value }`
- Avoid `self.method_name` for private method calls; use direct `method_name`

### Controllers
1. **HTTP method + route comment** — every action must have a comment with HTTP method and route:
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
2. **RESTful CRUD** — prefer standard actions (index, show, new, create, edit, update, destroy)
3. **Service delegation** — business logic goes in `app/services/`, not in controllers
4. **Minimize instance variables** — keep to 1-3 ivars per action for view-bound data
5. **Public vs Admin** — public controllers inherit from `ApplicationController`; admin controllers inherit from `Admin::BaseController`

### Models
1. **Schema annotations** — use `annotate` gem so schema info is displayed at top of each model file
2. **Association ordering** — define in this order: `belongs_to`, `has_many`, `has_one`, `has_many :through`
3. **Validations grouping** — group by type: presence, uniqueness, format, numericality, comparison
4. **Scopes** — defined after associations/validations, ordered alphabetically
5. **Enums** — use Rails 7+ keyword syntax: `enum :name, { key: value }`
6. **Callbacks** — minimize callbacks; prefer service objects for complex logic
7. **Monies** — all prices stored in **cents** (integer column), named `*_cents`

**Example model structure:**
```ruby
# == Schema Information
#
# Table name: bookings
#
#  id          :bigint           not null, primary key
#  status      :integer          default("pending"), not null
#  total_cents :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Booking < ApplicationRecord
  belongs_to :property
  has_many :availabilities, dependent: :nullify

  enum :status, {
    pending: 0, confirmed: 1, cancelled: 2
  }

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :total_cents, presence: true, numericality: { greater_than: 0 }
  validates :check_out, comparison: { greater_than: :check_in }

  scope :upcoming, -> { where('check_in > ?', Date.current).order(check_in: :asc) }
  scope :past, -> { where(check_out: ...Date.current).order(check_out: :desc) }

  def balance_due_cents
    total_cents - amount_paid_cents
  end
end
```

### Routes
1. **Comment format** — use identical comment style to controllers:
   ```ruby
   # GET /
   root 'pages#home'

   # GET /the-retreat
   get 'the-retreat', to: 'pages#retreat'
   ```
2. **Resourceful routes** — use `resources` for CRUD endpoints
3. **Admin routes** — namespaced under `/admin`
4. **Public pages** — explicit `get` for static pages, grouped together
5. **Keep routes file sorted** — group public pages first, then resources, then admin

### Service Objects
1. Location: `app/services/`
2. Naming: `<Action><Target>Service` (e.g., `BookingService`, `StripeCheckoutService`)
3. Pattern: POROs with a single `#call` method
4. Return: OpenStruct with `success?` and relevant data
5. No view logic

**Example:**
```ruby
class BookingService
  def initialize(params)
    @params = params
  end

  def call
    Booking.transaction do
      booking = Booking.create!(@params)
      OpenStruct.new(success?: true, booking: booking)
    end
  rescue ActiveRecord::RecordInvalid => e
    OpenStruct.new(success?: false, error: e.message)
  end
end
```

### Views
1. **File path comment** — top of each view file: `<%# pages/home.html.erb %>`
2. **ERB formatting** — use `<%` for logic, `<%=` for output
3. **Partials** — prefix filenames with `_`; use `render` with locals
4. **No complex logic in views** — use helpers, decorators, or view components
5. **Comments on complex code** — add explanatory comments for non-obvious logic, business rules, tricky queries, or workarounds

### Helpers / Concerns
1. Helpers in `app/helpers/` for view-related formatting
2. Concerns in `app/controllers/concerns/` and `app/models/concerns/`
3. Concerns named with present participle: `Bookable`, `Pricable`
4. Avoid concern bloat — prefer service objects for complex logic

## Key Conventions
- All prices stored in **cents** (integer) — never floats for money. Column naming: `*_cents`
- Enums use Rails 7+ keyword syntax: `enum :name, { key: value }` on models
- Service objects in `app/services/` for business logic
- Admin routes namespaced under `/admin` with `Admin::BaseController` parent
- Public booking flow: `/availability` -> `/book` -> `/book/:id/payment` -> `/book/:id/confirmation`
- Stripe webhook at `/webhooks/stripe` with signature verification
- RSpec request specs for controllers, model specs for validations/associations
- FactoryBot for test data, Faker for realistic values
- **Pagination** using Pagy gem
- **Search/filtering** using Ransack gem (admin area)
- **Rate limiting** using Rack::Attack
- **File uploads** using Active Storage (AWS S3 in production)

## Testing Standards (RSpec)

### General
- **FactoryBot** — use for test data creation (files in `spec/factories/`)
- **Faker** — use for realistic random data
- **shoulda-matchers** — use for association/validation one-liners
- **Request specs** — for controller testing (not controller specs)
- **Model specs** — for model validations, associations, scopes, and methods
- **System specs** — for browser/integration tests (Capybara + Selenium)
- **VCR** — for HTTP request recording (Stripe, external APIs)
- **SimpleCov** — for test coverage reports

### Spec Organization
- File path mirrors source: `spec/models/` for `app/models/`, `spec/requests/` for controllers
- Support files in `spec/support/`
- Use `let(:variable)` for setup; use FactoryBot traits for variations
- Aim for 1 assertion per example; use `context` blocks for scenarios
- Use `subject` for the primary object under test

### Request Spec Example
```ruby
require 'rails_helper'

RSpec.describe "PagesController", type: :request do
  describe "GET /" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /the-retreat" do
    it "returns http success" do
      get "/the-retreat"
      expect(response).to have_http_status(:success)
    end
  end
end
```

### Model Spec Example
```ruby
require 'rails_helper'

RSpec.describe Booking, type: :model do
  describe 'associations' do
    it { should belong_to(:property) }
    it { should have_many(:availabilities).dependent(:nullify) }
  end

  describe 'validations' do
    it { should validate_presence_of(:guest_name) }
    it { should validate_presence_of(:guest_email) }
  end

  describe 'scopes' do
    # ...
  end
end
```

## RuboCop Configuration

### Plugins
- **rubocop-rails** — Rails-specific rules
- **rubocop-rspec** — RSpec-specific rules
- **rubocop-performance** — Performance optimization rules

### Key Overrides (from `.rubocop.yml`)
| Rule | Value | Notes |
|---|---|---|
| `Style/Documentation` | `false` | No forced class/module docs |
| `Style/FrozenStringLiteralComment` | `false` | Not required |
| `Metrics/MethodLength` | `Max: 20` | Max 20 lines per method |
| `RSpec/ExampleLength` | `Max: 10` | Max 10 lines per spec example |
| `Rails/I18nLocaleTexts` | `false` | I18n not enforced in views |
| `Metrics/BlockLength` | Excluded for `spec/**/*`, `config/routes.rb`, `config/environments/*` |
| `Layout/LineLength` | Excluded for `config/initializers/devise.rb` |

### Commands
```bash
bundle exec rubocop              # check all files
bundle exec rubocop -a           # auto-fix safe offenses
bundle exec rubocop -A           # auto-fix all offenses (including unsafe)
```

## Architecture Patterns
1. **Hotwire** — Turbo + Stimulus for interactive UIs (no vanilla JS where possible)
2. **importmap** — manage JavaScript dependencies via importmap-rails (no Webpack/Node)
3. **Background Jobs** — Sidekiq + Redis for async tasks (emails, cleanup, etc.)
4. **Payments** — Stripe Checkout Sessions with webhook signature verification at `/webhooks/stripe`
5. **File Uploads** — Active Storage (AWS S3 in production)
6. **Search/Filtering** — Ransack gem for admin search/filtering
7. **Pagination** — Pagy gem (lightweight, fast)
8. **Rate Limiting** — Rack::Attack for request throttling
9. **Authentication** — Devise for admin users
10. **Authorization** — CanCanCan for role-based access

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

## Error Handling
1. Use `rescue` in controllers for user-facing errors
2. Use service object return values (with `success?`) for expected failure paths — not exceptions
3. Catch and log unexpected errors; show user-friendly 404/500 pages
4. Validate at model level; display errors in forms with Rails `form_with` defaults

## Future Improvements

### Pending Booking Cleanup
Unpaid pending bookings (created at booking form submission but before payment) do not block dates on the calendar. However, they should be cleaned up automatically to avoid database clutter.

A Sidekiq scheduled job should be added to:
- Cancel pending bookings older than **30 minutes** (not 30 days — 30 minutes is sufficient for a payment flow)
- Release any dates that were marked as booked during payment if the booking was cancelled
- Send a notification email to the guest if their pending booking was cancelled due to non-payment

Example job structure:
```ruby
class PendingBookingCleanupJob
  include Sidekiq::Job
  sidekiq_options retry: 2, queue: :default

  def perform
    # Cancel pending bookings older than 30 minutes
    # Release their held dates
    # Send cancellation notifications
  end
end
```

See `app/services/booking_service.rb` and `app/services/availability_service.rb#mark_available` for the relevant methods.

## Documentation
- Full SRS: `claude/docs/SRS.md`

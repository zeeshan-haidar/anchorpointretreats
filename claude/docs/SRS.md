# Software Requirements Specification (SRS)

## The Anchorpoint Retreat — Colorado Property Rental Website

**Version:** 1.0
**Date:** 2026-04-28
**Status:** Draft

---

## Implementation Progress

> **Key:** ✅ Complete | ◐ In Progress | ⬜ Not Started
> Last updated: 2026-06-08

### Phase 1: Foundation (Week 1-2)
| Task | Status | Notes |
|------|--------|-------|
| Rails 7 project initialization (PostgreSQL, Bootstrap, importmap) | ✅ | ✅ Rails created, DB configured, template assets copied, app boots and renders. |
| RuboCop configuration | ✅ | |
| Database migrations for all tables | ✅ | ✅ 9 tables: admin_users, properties, property_images, amenities, seasonal_pricings, availabilities, bookings, inquiries, testimonials, site_contents. All migrated.
| Seed script with realistic property data | ✅ | ✅ 1 admin, 1 property, 18 amenities, 4 pricings, 366 availabilities, 5 testimonials, 12 site contents.
| Model layer (validations, associations, enums, scopes) | ✅ | ✅ All 10 models with annotate schema, enums, validations, scopes. RuboCop clean.
| RSpec setup and model specs | ✅ | |
| Application layout (Header + Footer partials) | ✅ | Layout created from template. Header/footer partials pending. |
| Homepage with all 11 sections (using seed data) | ✅ | ⚠️ Section 9 (Testimonials) uses hardcoded HTML instead of looping over Testimonial model records. Needs controller action to pass @testimonials and migration to add avatar image field. See Section 5.2  table notes. |
| Pages: `/the-retreat`, `/experience`, `/about` | ✅ | |
| Stimulus controllers (scroll, menu, counter, carousel, lightbox) | ✅ | ✅ 5 controllers: scroll_animation, mobile_menu, counter, carousel, lightbox. |
| Responsive design across all breakpoints | ✅ | ✅ Template CSS is responsive across breakpoints. |
| **Deliverable: Fully styled, responsive public website with static content** | ✅ | ✅ All Phase 1 tasks complete. App boots, RuboCop clean, 8 specs pass.

### ⚠️ Phase 1 Known Issues (Pending Fix)
| Issue | Details |
|-------|---------|
| Testimonials section is hardcoded | Section 9 uses static HTML instead of iterating over `Testimonial` model records. Needs: (1) controller to fetch `@testimonials`, (2) Active Storage migration (`has_one_attached :image`) to attach author photos, (3) replace static HTML with `<% @testimonials.each do \|t\| %>` loop. |
| Testimonial author images missing | The `testimonials` table has no photo/avatar column. The model does not have `has_one_attached :image`. A new migration is needed. |
| Font files not loading | `fontawesome.css` and `fonts.css` reference webfonts via relative URLs (`../../webfonts/`) which 404 in Rails. Symlink `public/webfonts -> ../app/assets/webfonts` created as workaround. Proper fix: add `app/assets/webfonts` to `Rails.application.config.assets.paths`. |
| `.env.development` needs manual creation | `dotenv-rails` gem added, but `.env.development` file must be manually created with `DB_USERNAME`, `DB_PASSWORD`, `DB_HOST` (security tools prevent auto-creation). |
| Amenities icons use FontAwesome instead of SVG | Section 7 uses `<i class="fa-solid fa-...">` inside `service-icon` divs. `.amenity-icon` CSS override added with `!important` on color rule for white icons. |

### Phase 2: Availability & Booking (Week 3-4)
| Task | Status | Notes |
|------|--------|-------|
| Availability calendar Stimulus controller | ✅ | `availability_calendar_controller.js` with month nav, date selection, range highlighting, pricing AJAX |
| AvailabilityService — fetch available dates | ✅ | Calendar data generation, availability range checking, mark booked/available |
| PricingService — calculate totals | ✅ | Nightly rate, subtotal, cleaning fee, taxes (8.5%), seasonal overrides |
| `/availability` page with calendar + price preview | ✅ | Interactive calendar, date range selection, dynamic pricing sidebar, guest count selector |
| `/book` form with server-side validation | ✅ | Guest details form with validated fields, pre-populated dates, price summary sidebar |
| BookingService — create bookings | ✅ | Confirmation number generation, pricing calculation, availability locking in transaction |
| `/inquiry` form + InquiryService | ✅ | Form with name, email, phone, company, retreat type, dates, group size, message; rate limiting support |
| Controller and request specs | ✅ | 30 request specs for Availability, Bookings, Inquiries controllers |
| Model specs for new models | ✅ | 44 model specs for Availability, Booking, Inquiry (associations, validations, enums, scopes) |
| Service specs | ✅ | 39 service specs for all 4 services |
| Calendar CSS and form styles | ✅ | Calendar grid, states (available/booked/blocked/past/selected/in-range), form controls, pricing summary |
| Navigation updated with new links | ✅ | Header: "Book Your Stay" CTA, "Availability" nav link. Footer: Availability & FAQ enabled. Home CTAs pointed to `/availability` |
| Routes configured | ✅ | All Phase 2 routes: availability, book/booking/*, inquiry/* |
| **Deliverable: Calendar, prices, bookings, inquiries** | ✅ | **Total: 113 RSpec examples, 0 failures** |

### Phase 3: Stripe & Email (Week 5)

> ⚠️ **Local testing setup**: Run `stripe listen --forward-to localhost:3000/webhooks/stripe` in a terminal, then copy the `whsec_...` signing secret into `.env.development` as `STRIPE_WEBHOOK_SIGNING_SECRET`.

| Task | Status | Notes |
|------|--------|-------|
| Stripe gem setup, initializer, StripeCheckoutService | ✅ | Checkout Sessions for full payment only (deposit option removed), metadata, idempotency |
| StripeWebhookService -- construct_event + process_event | ✅ | Signature verification, checkout.session.completed/expired, charge.refunded handling |
| /webhooks/stripe endpoint with CSRF skip | ✅ | WebhooksController, route added |
| Stripe checkout specs (11 tests) | ✅ | Full payment, nil booking, invalid state, invalid type, Stripe errors, metadata, customer email |
| Stripe webhook specs (12 tests) | ✅ | construct_event (no secret), process_event: full payment, expired, refunded, unhandled, already processed |
| Webhook request specs (6 tests) | ✅ | Success, JSON response, bad request on bad signature, unprocessable on processing failure, CSRF skip |
| Booking Mailer (confirmation, reminder, payment_link) | ✅ | 3 email types, HTML+text templates, formatted amounts, check-in instructions |
| Inquiry Mailer (received, new_inquiry_alert) | ✅ | 2 email types, HTML+text templates, replaced admin_inquiry_url link |
| Mailer specs (12 tests) | ✅ | All rendering correctly (headers, body content, dates, currency formatting) |
| BookingReminderJob | ✅ | Sidekiq scheduled job for 7-day reminder |
| ~~PaymentReminderJob~~ | ❌ Removed | Deposit payment feature removed; job is no longer needed |
| Letter Opener gem for local email preview | ✅ | development.rb configured with delivery_method = letter_opener |
| ApplicationMailer default from address | ✅ | hello@anchorpointretreat.com |
| Development env config (letter_opener, default URL options) | ✅ | |
| Production env config (SMTP via env vars) | ✅ | SMTP_ADDRESS, _PORT, _DOMAIN, _USERNAME, _PASSWORD |
| **Deliverable: End-to-end payment flow with notifications** | ✅ | **Total: 156 RSpec examples, 0 failures** |

### Phase 4: Admin Panel (Week 6-7)
| Task | Status | Notes |
|------|--------|-------|
| Devise setup for AdminUser | ⬜ | |
| CanCanCan Ability class with role-based permissions | ⬜ | |
| Admin layout with sidebar navigation | ⬜ | |
| Dashboard with stats | ⬜ | |
| Calendar management page | ⬜ | |
| Bookings CRUD with filters, pagination, status | ⬜ | |
| Inquiries CRUD with status management | ⬜ | |
| Property editor (details, photos, amenities, pricing) | ⬜ | |
| Testimonial management | ⬜ | |
| Site content editor | ⬜ | |
| Admin settings + user management | ⬜ | |
| **Deliverable: Full admin panel** | ⬜ | |

### Phase 5: Polish & Launch (Week 8)
| Task | Status | Notes |
|------|--------|-------|
| SEO (meta tags, OpenGraph, JSON-LD, sitemap, robots.txt) | ⬜ | |
| Performance (image variants, caching) | ⬜ | |
| Error pages (404, 500, 422) | ⬜ | |
| FAQ, policies, privacy, terms pages | ⬜ | |
| Accessibility audit and fixes | ⬜ | |
| Full RSpec test suite pass, RuboCop clean | ⬜ | |
| Production deployment | ⬜ | |
| **Deliverable: Production-ready launch** | ⬜ | |

---

## 1. Introduction

### 1.1 Purpose
This document defines the software requirements for a single-property rental website for a corporate retreat / wellness property located in Colorado. The website enables guests to browse the property, view availability, book stays with Stripe payments, and submit inquiries. An admin panel allows the property owner to manage availability, bookings, content, and pricing.

### 1.2 Scope
The system is a monolithic Ruby on Rails 7 web application serving:
- A public-facing marketing and booking website
- A protected admin panel for property management
- Stripe-integrated payment processing
- Transactional email notifications

### 1.3 Structure and Content Reference
The website's structure and content are inspired by [discoverwilder.com](https://discoverwilder.com/) — a premium, nature-forward layout with clear information hierarchy, distinct pages and content sections, and a luxury-meets-accessible approach adapted for a single Colorado rental property.

Design specifications (colors, typography, spacing, components, and animations) are defined by the included HTML template (`html-template/` — Obsidia wellness theme) and documented in Section 8.

### 1.4 Definitions
| Term | Definition |
|------|-----------|
| Guest | A public visitor who browses, books, or inquires |
| Admin | Property owner/manager with full system access |
| Booking | A confirmed or pending reservation for specific dates |
| Inquiry | A contact form submission from a potential guest |
| Availability | Per-day status of the property (available, booked, blocked) |
| Deposit | Partial upfront payment (default 25% of total) — ⚠️ Feature removed; column retained in schema only |

---

## 2. Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Language | Ruby | 3.3.8 |
| Framework | Ruby on Rails | 7.1.x |
| Database | PostgreSQL | 14+ |
| Testing | RSpec | latest |
| Linting | RuboCop | latest |
| Authentication | Devise | latest |
| Authorization | CanCanCan | latest |
| Payments | Stripe (stripe-ruby gem) | latest |
| Frontend | Rails 7 Hotwire (Turbo + Stimulus) | bundled with Rails 7 |
| CSS | Bootstrap (bootstrap gem) | latest |
| Background Jobs | Sidekiq + Redis | latest |
| Email | Action Mailer (with SMTP or Resend) | bundled |
| Image Upload | Active Storage + Cloudinary (or S3) | bundled |
| JavaScript Bundling | importmap-rails | bundled with Rails 7 |
| Icons | Font Awesome (from html-template) | bundled |
| Calendar UI | Stimulus + custom calendar component | — |
| Deployment | TBD (Render, Fly.io, or Heroku) | — |

---

## 3. System Overview

### 3.1 Architecture
```
                    +-------------------+
                    |   Web Browser     |
                    +--------+----------+
                             |
                    +--------v----------+
                    |   Rails 7 App     |
                    |  (Hotwire/Turbo)  |
                    +--------+----------+
                             |
              +--------------+--------------+
              |              |              |
     +--------v---+  +------v------+  +----v------+
     | PostgreSQL |  |   Sidekiq   |  |  Stripe   |
     |  Database  |  | (bg jobs)   |  |   API     |
     +------------+  +------+------+  +-----------+
                            |
                     +------v------+
                     |    Redis    |
                     +-------------+
```

### 3.2 User Roles

| Role | Description | Auth Method |
|------|------------|-------------|
| Guest (public) | Browses site, books stays, submits inquiries | No login required |
| Admin | Manages property, dates, bookings, content | Devise email/password login |
| Super Admin | Full access including admin user management | Devise + CanCanCan role |

---

## 4. Functional Requirements

### 4.1 Public Website

#### FR-001: Homepage
The homepage shall display the following sections in order:

| # | Section | Description |
|---|---------|------------|
| 1 | Navigation | Sticky header: logo, nav links (The Retreat, Experience, Availability, About), CTA button "Book Your Stay". Transparent over hero, solid white on scroll. Mobile hamburger menu. |
| 2 | Hero | Full-viewport background image/video of property with Colorado mountain setting. Large headline, subtitle, two CTAs: "Check Availability" (primary) and "Take a Tour" (secondary/scroll). |
| 3 | Metrics Bar | Dark horizontal strip with 3-4 animated counters: retreats hosted, guest rating, max guests, property acreage. Count-up animation on scroll. |
| 4 | Property Overview | Split layout — large image (left) + property story text with quick specs (bedrooms, bathrooms, guests, sqft) and "Explore the Property" link (right). |
| 5 | Experience Types | 3 tall portrait cards: Corporate Retreats, Wellness Retreats, Private Gatherings. Full-bleed images with gradient overlay text. Links to /experience sections. |
| 6 | Photo Gallery | Asymmetric masonry grid (2 large + 3 small photos). Click opens full-screen lightbox. "+N more" indicator on last image. |
| 7 | Amenities Grid | 8 featured amenities with icons in a 2x4 grid. Icon + name + one-line description each. "View All Amenities" link. |
| 8 | How It Works | 3 horizontal steps with icons and connecting line: Choose Your Dates -> Tell Us About Your Group -> Arrive and Unwind. CTA button below. |
| 9 | Testimonials | Carousel/slider of guest testimonials. Each: quote text, guest photo, name, title/company, star rating. Prev/next navigation + dots. |
| 10 | Availability CTA | Full-bleed nature image with dark overlay. Centered white text: headline "Ready to Plan Your Retreat?", subtext, and "View Availability" button. |
| 11 | Footer | 4-column layout: brand info + social links, navigation links, policy links, contact info + newsletter email signup. Bottom bar: copyright. |

#### FR-002: Property Details Page (`/the-retreat`)
- Full photo gallery with lightbox viewer
- Detailed property description (rich text)
- Property specifications: bedrooms, bathrooms, max guests, square footage
- Check-in/check-out times
- Full amenities list grouped by category (Wellness, Outdoor, Kitchen, Comfort, Workspace, Entertainment, Safety)
- Embedded map showing property location
- CTA to check availability

#### FR-003: Experience Page (`/experience`)
- Three sections: Corporate Retreats, Wellness Retreats, Private Gatherings
- Each section: hero image, description text, sample activities/itinerary ideas
- CTAs linking to booking/inquiry

#### FR-004: About Page (`/about`)
- Property story and history
- Owner/host introduction with photo
- Philosophy and values
- Location highlights (nearby attractions, activities)

#### FR-005: Availability Page (`/availability`)
- Interactive calendar displaying available, booked, and blocked dates
- Color coding: green = available, red = booked, gray = blocked
- Date range selection for check-in / check-out
- Dynamic price calculation on date selection showing:
  - Nightly rate(s)
  - Number of nights
  - Cleaning fee
  - Taxes
  - Total
- Guest count selector
- "Book Now" button (enabled when valid dates selected)
- "Have Questions? Submit an Inquiry" link

#### FR-006: Booking Flow
**Step 1 — Guest Details (`/book?check_in=DATE&check_out=DATE&guests=N`)**
- Pre-populated date range and guest count from availability page
- Form fields:
  - Full name (required)
  - Email (required, validated)
  - Phone (optional)
  - Company name (optional)
  - Retreat type dropdown: Corporate, Wellness, Private, Other (optional)
  - Special requests (textarea, optional)
- Price summary sidebar showing full breakdown
- "Proceed to Payment" button
- Server-side validation; booking created with status `pending`

**Step 2 — Payment (`/book/:id/payment`)**
- Payment option: "Pay Full Amount" — complete one-time payment
- Clicking creates a Stripe Checkout Session and redirects to Stripe's hosted payment page
- Stripe handles all card input (PCI compliance)
- Cancel URL returns to payment page

**Step 3 — Confirmation (`/book/:id/confirmation`)**
- Displayed after successful Stripe payment (redirect from Stripe)
- Shows: confirmation number, dates, guest count, amount paid
- Booking details summary
- "Add to Calendar" link (iCal download)
- Confirmation email sent automatically

#### FR-007: Inquiry Form (`/inquiry`)
- Form fields:
  - Name (required)
  - Email (required)
  - Phone (optional)
  - Company (optional)
  - Retreat type dropdown (optional)
  - Preferred dates (text, optional)
  - Group size (number, optional)
  - Message (textarea, required)
- Rate limited: max 5 submissions per IP per hour
- On submit: creates inquiry record, sends notification email to admin, shows thank-you page
- Thank-you page (`/inquiry/thank-you`): confirmation message with expected response time

#### FR-008: Static Pages
- **FAQ** (`/faq`): Accordion-style expandable Q&A items, admin-editable
- **Policies** (`/policies`): Cancellation policy, house rules, terms of stay
- **Privacy Policy** (`/privacy`)
- **Terms of Service** (`/terms`)

---

### 4.2 Stripe Payment Integration

#### FR-009: Payment Processing
- **Flow**: Stripe Checkout Sessions (redirect-based)
- **Payment type**: Full payment only (deposit option removed)
- **Webhook endpoint** (`/webhooks/stripe`):
  - Listens for: `checkout.session.completed`, `checkout.session.expired`, `charge.refunded`
  - On `checkout.session.completed`:
    - Update booking status to `fully_paid`
    - Update `amount_paid` on booking
    - Mark selected dates as `booked` in availability
    - Send confirmation email
  - On `charge.refunded`:
    - Update booking status to `refunded`
    - Release dates back to `available`
  - Signature verification on all webhook requests
  - Idempotency: store `stripe_session_id` to prevent double-processing
- **Checkout Session metadata**: booking_id
- **Session expiration**: 30 minutes
- **Refunds**: Initiated by admin from admin panel, calls Stripe Refunds API

> **Note:** Deposit payment option and `PaymentReminderJob` have been removed. The `deposit_amount_cents` and `deposit_percentage` columns remain in the database schema for potential future use but are not currently utilized.

---

### 4.3 Admin Panel

All admin routes are under `/admin` and require Devise authentication. CanCanCan enforces role-based authorization.

#### FR-011: Admin Dashboard (`/admin`)
- Stat cards: total revenue (this month), upcoming bookings count, occupancy rate (this month), new inquiries count
- Upcoming bookings list: next 5 bookings with guest name, dates, status, link to detail
- Recent inquiries list: last 5 inquiries with name, date, status
- Quick actions: block dates, view calendar, export bookings CSV

#### FR-012: Calendar Management (`/admin/calendar`)
- Full month-view calendar grid
- Color-coded dates: green (available), red (booked), gray (blocked), yellow (pending)
- Click a single date to toggle available/blocked
- Click + drag (or shift-click) to select a date range, then bulk-set status
- Clicking a booked date shows booking details in a sidebar/modal
- Per-date price override capability
- Month navigation (prev/next)

#### FR-013: Booking Management (`/admin/bookings`)
- Paginated table of all bookings
- Filters: status dropdown, date range, search by guest name/email
- Sortable columns: check-in date, status, total, created date
- Columns: confirmation #, guest name, check-in, check-out, guests, total, status, actions

**Booking Detail (`/admin/bookings/:id`)**:
- Full guest info and booking details
- Payment history (amount paid, payment method, Stripe links)
- Status update actions: confirm, cancel, mark checked-in, mark completed
- Admin notes field (internal, not visible to guest)
- Refund action (partial or full, triggers Stripe refund)
- Send payment reminder email action
- Send custom email to guest

#### FR-014: Inquiry Management (`/admin/inquiries`)
- Paginated table: name, email, retreat type, date submitted, status
- Filters: status (new, responded, closed)

**Inquiry Detail (`/admin/inquiries/:id`)**:
- Full inquiry details
- Status update: new -> responded -> closed
- Admin notes field
- Quick reply via email (opens mailer with guest's email)

#### FR-015: Property Management (`/admin/property`)
- **Details tab**: Edit property name, tagline, description (rich text), address, city, zip, coordinates, bedrooms, bathrooms, max guests, square footage, check-in/out times
- **Photos tab**: Drag-and-drop upload via Active Storage, sortable grid with drag handles, category assignment (Hero, Exterior, Interior, Bedroom, Bathroom, Kitchen, Living, Outdoor, Amenity, Aerial), alt text editing, delete with confirmation
- **Amenities tab**: CRUD list with name, description, icon selection, category (Wellness, Outdoor, Kitchen, Comfort, Workspace, Entertainment, Safety), featured toggle, drag-to-reorder
- **Pricing tab**: Base price per night, cleaning fee, min/max nights. Seasonal pricing table: add/edit/delete date ranges with custom nightly rate and optional min-night override

#### FR-016: Testimonial Management (`/admin/testimonials`)
- CRUD for testimonials: author name, title, photo upload, quote text, rating (1-5), retreat type, featured toggle, sort order

#### FR-017: Site Content Management (`/admin/content`)
- Key-value editor for editable site text:
  - Hero headline, hero subtitle
  - About section text
  - Experience section descriptions
  - Metrics bar values and labels
  - FAQ items (question + answer pairs)
- Markdown support for longer text blocks

#### FR-018: Admin Settings (`/admin/settings`)
- Update admin account email/password
- Notification preferences (email on new booking, new inquiry)
- Super admin: manage other admin users (invite, deactivate)

---

### 4.4 Email Notifications

#### FR-019: Transactional Emails
All emails sent via Action Mailer.

| Email | Trigger | Recipient | Content |
|-------|---------|-----------|---------|
| Booking Confirmation | Successful payment webhook | Guest | Confirmation #, dates, amount paid, property details, check-in instructions |
| Booking Reminder | 7 days before check-in (Sidekiq scheduled) | Guest | Upcoming stay reminder, check-in time, directions |
| Payment Reminder | Admin-triggered | Guest | Outstanding balance, payment link |
| Inquiry Received | Inquiry form submitted | Guest | Thank you, expected response time |
| New Inquiry Alert | Inquiry form submitted | Admin | Inquiry details, link to admin panel |
| New Booking Alert | Booking created | Admin | Booking details, link to admin panel |
| Cancellation Notice | Booking cancelled | Guest | Cancellation confirmation, refund details |

---

## 5. Database Schema

### 5.1 Entity Relationship Overview
```
admin_users (Devise)
    |
property ──────────────┬── property_images
    |                   ├── amenities
    |                   ├── seasonal_pricings
    |                   └── availabilities ──── bookings
    |
    ├── inquiries
    ├── testimonials
    └── site_contents
```

### 5.2 Table Definitions

#### `admin_users`
| Column | Type | Constraints | Notes |
|--------|------|------------|-------|
| id | bigint | PK, auto | |
| email | string | unique, not null | Devise field |
| encrypted_password | string | not null | Devise field |
| name | string | not null | |
| role | enum | not null, default: admin | Values: super_admin, admin |
| reset_password_token | string | | Devise field |
| reset_password_sent_at | datetime | | Devise field |
| remember_created_at | datetime | | Devise field |
| sign_in_count | integer | default: 0 | Devise trackable |
| current_sign_in_at | datetime | | Devise trackable |
| last_sign_in_at | datetime | | Devise trackable |
| current_sign_in_ip | string | | Devise trackable |
| last_sign_in_ip | string | | Devise trackable |
| timestamps | | | |

#### `properties`
| Column | Type | Constraints | Notes |
|--------|------|------------|-------|
| id | bigint | PK, auto | |
| name | string | not null | "The Anchorpoint Retreat" |
| tagline | string | | Hero subtitle |
| description | text | | Rich text / markdown |
| short_description | string | | For meta tags / cards |
| address | string | | |
| city | string | | e.g., "Telluride" |
| state | string | default: "CO" | |
| zip | string | | |
| latitude | decimal(10,7) | | |
| longitude | decimal(10,7) | | |
| bedrooms | integer | not null | |
| bathrooms | integer | not null | |
| max_guests | integer | not null | |
| square_feet | integer | | |
| base_price_cents | integer | not null | Price per night in cents |
| cleaning_fee_cents | integer | not null, default: 0 | |
| deposit_percentage | integer | default: 25 | ⚠️ Not currently used (deposit feature removed) |
| min_nights | integer | default: 2 | |
| max_nights | integer | default: 30 | |
| check_in_time | string | default: "3:00 PM" | |
| check_out_time | string | default: "11:00 AM" | |
| timestamps | | | |

#### `property_images`
| Column | Type | Constraints | Notes |
|--------|------|------------|-------|
| id | bigint | PK, auto | |
| property_id | bigint | FK, not null | |
| image | | Active Storage attached | |
| alt_text | string | | |
| caption | string | | |
| category | enum | not null | hero, exterior, interior, bedroom, bathroom, kitchen, living, outdoor, amenity, aerial |
| sort_order | integer | default: 0 | |
| timestamps | | | |

#### `amenities`
| Column | Type | Constraints | Notes |
|--------|------|------------|-------|
| id | bigint | PK, auto | |
| property_id | bigint | FK, not null | |
| name | string | not null | "Private Hot Tub" |
| description | string | | |
| icon | string | | Lucide icon name |
| category | enum | not null | wellness, outdoor, kitchen, comfort, workspace, entertainment, safety |
| sort_order | integer | default: 0 | |
| featured | boolean | default: false | Show on homepage |
| timestamps | | | |

#### `seasonal_pricings`
| Column | Type | Constraints | Notes |
|--------|------|------------|-------|
| id | bigint | PK, auto | |
| property_id | bigint | FK, not null | |
| name | string | not null | "Peak Winter", "Summer" |
| start_date | date | not null | |
| end_date | date | not null | |
| price_per_night_cents | integer | not null | Overrides base_price |
| min_nights | integer | | Override min_nights |
| timestamps | | | |

#### `availabilities`
| Column | Type | Constraints | Notes |
|--------|------|------------|-------|
| id | bigint | PK, auto | |
| property_id | bigint | FK, not null | |
| date | date | not null | |
| status | enum | not null, default: available | available, booked, blocked, maintenance |
| booking_id | bigint | FK, nullable | Set when status=booked |
| price_override_cents | integer | | Per-day price override |
| timestamps | | | |
| | | unique: [property_id, date] | |

#### `bookings`
| Column | Type | Constraints | Notes |
|--------|------|------------|-------|
| id | bigint | PK, auto | |
| property_id | bigint | FK, not null | |
| confirmation_number | string | unique, not null | Auto-generated (e.g., SR-20260428-A1B2) |
| check_in | date | not null | |
| check_out | date | not null | |
| num_guests | integer | not null | |
| guest_name | string | not null | |
| guest_email | string | not null | |
| guest_phone | string | | |
| company_name | string | | |
| retreat_type | string | | corporate, wellness, private, other |
| special_requests | text | | |
| num_nights | integer | not null | |
| nightly_rate_cents | integer | not null | Locked-in avg rate |
| subtotal_cents | integer | not null | |
| cleaning_fee_cents | integer | not null | |
| taxes_cents | integer | not null | |
| total_cents | integer | not null | |
| deposit_amount_cents | integer | not null | ⚠️ Not currently used (deposit feature removed) |
| amount_paid_cents | integer | default: 0 | |
| status | enum | not null, default: pending | pending, ~~deposit_paid~~, fully_paid, confirmed, checked_in, completed, cancelled, refunded |
| stripe_checkout_session_id | string | | |
| stripe_payment_intent_id | string | | |
| admin_notes | text | | Internal notes |
| timestamps | | | |

#### `inquiries`
| Column | Type | Constraints | Notes |
|--------|------|------------|-------|
| id | bigint | PK, auto | |
| name | string | not null | |
| email | string | not null | |
| phone | string | | |
| company | string | | |
| retreat_type | string | | |
| preferred_dates | string | | Free text |
| group_size | integer | | |
| message | text | not null | |
| status | enum | not null, default: new_inquiry | new_inquiry, responded, closed |
| admin_notes | text | | |
| timestamps | | | |

#### `testimonials`
| Column | Type | Constraints | Notes |
|--------|------|------------|-------|
| id | bigint | PK, auto | |
| author_name | string | not null | |
| author_title | string | | "CEO, Acme Corp" |
| author_image | | Active Storage attached | ⚠️ NOT YET IMPLEMENTED — model lacks image/photo/avatar column. Needs migration to attach Active Storage image. Homepage currently uses static /assets/dummy-img-600x600.jpg. |
| content | text | not null | Quote text |
| rating | integer | default: 5 | 1-5 |
| retreat_type | string | | |
| featured | boolean | default: false | |
| sort_order | integer | default: 0 | |
| timestamps | | | |

#### `site_contents`
| Column | Type | Constraints | Notes |
|--------|------|------------|-------|
| id | bigint | PK, auto | |
| key | string | unique, not null | "hero_headline", "about_text" |
| value | text | not null | |
| content_type | enum | default: text | text, html, url, json |
| timestamps | | | |

---

## 6. Routes / URL Structure

### 6.1 Public Routes

| Method | Path | Controller#Action | Description |
|--------|------|-------------------|------------|
| GET | / | pages#home | Homepage |
| GET | /the-retreat | property#show | Property details |
| GET | /experience | pages#experience | Experience types |
| GET | /about | pages#about | About page |
| GET | /availability | availability#index | Calendar + booking start |
| GET | /availability/calendar | availability#calendar | JSON: available dates for month |
| GET | /availability/pricing | availability#pricing | JSON: price calculation |
| GET | /book | bookings#new | Booking form |
| POST | /book | bookings#create | Create booking |
| GET | /book/:id/payment | bookings#payment | Payment options |
| POST | /book/:id/checkout | bookings#checkout | Create Stripe session, redirect |
| GET | /book/:id/confirmation | bookings#confirmation | Post-payment confirmation |
| GET | /inquiry | inquiries#new | Inquiry form |
| POST | /inquiry | inquiries#create | Submit inquiry |
| GET | /inquiry/thank-you | inquiries#thank_you | Confirmation |
| GET | /faq | pages#faq | FAQ page |
| GET | /policies | pages#policies | Policies page |
| GET | /privacy | pages#privacy | Privacy policy |
| GET | /terms | pages#terms | Terms of service |
| POST | /webhooks/stripe | webhooks#stripe | Stripe webhook |

### 6.2 Admin Routes (under `/admin`, Devise-authenticated)

| Method | Path | Controller#Action | Description |
|--------|------|-------------------|------------|
| GET | /admin/login | devise sessions | Login page |
| POST | /admin/login | devise sessions | Authenticate |
| DELETE | /admin/logout | devise sessions | Logout |
| GET | /admin | admin/dashboard#index | Dashboard |
| GET | /admin/calendar | admin/calendar#index | Calendar management |
| POST | /admin/calendar/bulk_update | admin/calendar#bulk_update | Bulk date update |
| PATCH | /admin/calendar/:date | admin/calendar#update | Single date update |
| GET | /admin/bookings | admin/bookings#index | Booking list |
| GET | /admin/bookings/:id | admin/bookings#show | Booking detail |
| PATCH | /admin/bookings/:id | admin/bookings#update | Update booking |
| POST | /admin/bookings/:id/refund | admin/bookings#refund | Stripe refund |
| POST | /admin/bookings/:id/send_payment_link | admin/bookings#send_payment_link | Email payment link |
| GET | /admin/inquiries | admin/inquiries#index | Inquiry list |
| GET | /admin/inquiries/:id | admin/inquiries#show | Inquiry detail |
| PATCH | /admin/inquiries/:id | admin/inquiries#update | Update status/notes |
| GET | /admin/property | admin/property#edit | Edit property |
| PATCH | /admin/property | admin/property#update | Save property |
| CRUD | /admin/property/photos | admin/photos#* | Photo management |
| POST | /admin/property/photos/reorder | admin/photos#reorder | Reorder photos |
| CRUD | /admin/property/amenities | admin/amenities#* | Amenity management |
| CRUD | /admin/property/pricing | admin/seasonal_pricings#* | Seasonal pricing |
| CRUD | /admin/testimonials | admin/testimonials#* | Testimonial management |
| GET | /admin/content | admin/content#index | Content editor |
| PATCH | /admin/content/:id | admin/content#update | Update content |
| GET | /admin/settings | admin/settings#edit | Admin settings |
| PATCH | /admin/settings | admin/settings#update | Save settings |
| GET | /admin/bookings/export.csv | admin/bookings#export | CSV download |

---

## 7. Non-Functional Requirements

### 7.1 Performance
- Page load time: < 2 seconds on 3G connection
- Time to Interactive: < 3 seconds
- Lighthouse Performance score: > 85
- Image optimization: responsive images via Active Storage variants, lazy loading below the fold
- Database queries: N+1 prevention via `includes`/`eager_load`, indexed foreign keys and date columns

### 7.2 Security
- CSRF protection on all forms (Rails default)
- Stripe webhook signature verification
- Rate limiting on public forms (rack-attack gem): 5 inquiries/hour per IP, 10 bookings/hour per IP
- Admin routes protected by Devise authentication + CanCanCan authorization
- All prices calculated server-side (never trust client-submitted prices)
- Input sanitization on all user-submitted text
- HTTPS enforced in production
- Sensitive data (Stripe keys, DB credentials) in environment variables only
- No secrets in version control

### 7.3 Responsiveness
- Fully responsive at breakpoints: 375px (mobile), 768px (tablet), 1024px (laptop), 1440px (desktop)
- Mobile-first design approach
- Touch-friendly interactive elements (min 44px tap targets)

### 7.4 SEO
- Server-rendered HTML (Rails default)
- Semantic HTML5 elements
- OpenGraph and Twitter Card meta tags on all pages
- JSON-LD structured data (LodgingBusiness schema)
- `sitemap.xml` generation
- `robots.txt`
- Canonical URLs

### 7.5 Accessibility
- WCAG 2.1 AA compliance
- Keyboard navigable (focus management, skip links)
- ARIA labels on interactive elements
- Sufficient color contrast ratios (4.5:1 for text)
- Alt text on all images
- Form labels and error messages associated with inputs

### 7.6 Browser Support
- Chrome 90+, Firefox 90+, Safari 15+, Edge 90+
- iOS Safari 15+, Android Chrome 90+

### 7.7 Testing
- RSpec for all models, controllers, services, and mailers
- Model validations, associations, scopes
- Controller request specs for public and admin routes
- Service object specs for booking, pricing, and Stripe logic
- Mailer specs
- System/integration specs for critical flows (booking, payment, admin calendar)
- Target: > 80% code coverage

---

## 8. Design Specifications

### 8.1 Color Palette
| Token | Hex | Usage |
|-------|-----|-------|
| Deep Espresso (Primary) | #312B24 | Main text color, headings, primary UI elements |
| Soft Sage (Secondary) | #EAF0EA | Page background, section backgrounds, light surfaces |
| Muted Gray (Text) | #747474 | Secondary text, descriptions, meta information |
| Sage Green (Accent) | #64734F | Primary accent color, CTAs, highlights, links, icons |
| White (Accent 2) | #FFFFFF | Text on dark backgrounds, card backgrounds, buttons |
| Deep Green (Accent 3) | #1A312A | Dark overlays, rich backgrounds, banner overlays |
| Light Taupe (Accent 4) | #D6D1CC | Subtle backgrounds, borders, dividers, card backgrounds |
| Black (Accent 5) | #000000 | Maximum contrast elements, deep shadows |
| Accent Transparent | #00000000 | Fully transparent overlay, gradient endpoints |
| Overlay Dark | #00000087 | Semi-transparent overlays (53% opacity) |
| Success | (use Deep Green #1A312A) | Success states |
| Error | (use Deep Green #1A312A) | Form errors (defined in template) |

### 8.2 Typography
| Element | Font | Weight | Size | Line Height |
|---------|------|--------|------|-------------|
| Headings (h1) | Lora | 400 | 5.1rem (81.6px) | 1.2em |
| Headings (h2) | Lora | 400 | 3.1rem (49.6px) | 1.2em |
| Headings (h3) | Lora | 400 | 1.75rem (28px) | 1.2em |
| Headings (h4) | Lora | 400 | 1.4rem (22.4px) | 1.2em |
| Headings (h5) | Lora | 400 | 1.125rem (18px) | 1.2em |
| Headings (h6) | Lora | 400 | 0.938rem (15px) | 1.2em |
| Body | Inter Tight | 400 | 1rem (16px) | 1.2em |
| Buttons / Links | Lora | 400 | 0.938rem (15px) | 1.2em |
| Testimonial Stars | — | — | 0.875rem (14px) | — |

### 8.3 Spacing
- Base unit: 1em (16px root)
- Section padding (vertical): 6em (96px default), 4em (64px small), 7em (112px large)
- Section padding (horizontal): 1em (16px standard), 2em (32px large)
- Content max-width: 1440px (hero-container)
- Flex/Grid gap scale: 10px, 20px, 30px, 40px, 50px, 100px
- Card padding: 30px (standard cards)
- Form input padding: 14px 12px

### 8.4 Components
- Border radius: 0px (default - cards, buttons, inputs use sharp/square corners), 5px (subtle rounding on some inputs), 24px (pill-shaped buttons), 25px (newsletter form), 50% (avatars/circular images), 6px (alert boxes)
- Shadows: `0 10px 30px 0 rgba(45, 45, 45, .2)` (navbar dropdowns), `0px 0px 1px 0px rgba(0, 0, 0, 0.5)` (subtle checkbox/style elements)
- No box-shadow on inputs (clean, minimal approach); only bottom border on focus/hover
- Transitions: 0.3s ease (hover states, blog links, form inputs)
- Scroll animations: fade-up (translateY: 80px), fade-down (translateY: -80px), fade-left (translateX: -120px), fade-right (translateX: 120px)
- Animation durations: 0.8s (fast), 1.1s (normal), 1.6s (slow)
- Animation delays: 0s (none), 0.25s (sm), 0.45s (md)
- Stagger delay pattern for grids/lists: increment by 0.25s per item, max 5 items
- Image aspect ratios: 15vh (blog thumbnails), 35vh (wide gallery), 78vh (tall gallery), 80x80px (testimonials)
- Easing: `cubic-bezier(0.25, 0.8, 0.25, 1)` (standard), `cubic-bezier(0.4, 0.0, 0.2, 1)` (carousel/slider)

---

## 9. Implementation Phases

### Phase 1: Foundation (Week 1-2)
- Rails 7 project initialization with PostgreSQL, Bootstrap, importmap
- RuboCop configuration
- Database migrations for all tables
- Seed script with realistic property data
- Model layer: all models with validations, associations, enums, scopes
- RSpec setup and model specs
- Layout: application layout with Header and Footer partials
- Homepage with all 11 sections (using seed data)
- `/the-retreat`, `/experience`, `/about` pages
- Stimulus controllers for: scroll animations, mobile menu, counter animation, testimonial carousel, lightbox
- Responsive design across all breakpoints
- **Deliverable**: Fully styled, responsive public website with static content

### Phase 2: Availability & Booking (Week 3-4)
✅ - Availability calendar Stimulus controller
✅ - `AvailabilityService` — fetch available dates, check date ranges
✅ - `PricingService` — calculate total from dates, seasonal pricing, overrides
✅ - `/availability` page with interactive calendar + price preview
✅ - `/book` form with server-side validation
✅ - `BookingService` — create bookings, generate confirmation numbers
✅ - `/inquiry` form + `InquiryService`
✅ - Controller and request specs
✅ - **Deliverable**: Users can view calendar, see prices, submit bookings and inquiries

### Phase 3: Stripe & Email (Week 5)
- Stripe gem setup, `StripeService` for checkout session creation (full payment only)
- `/book/:id/payment` page with full payment option
- `/book/:id/confirmation` page
- Stripe webhook controller with signature verification
- Post-payment logic: update booking, mark availability, send emails
- Action Mailer templates: booking confirmation, inquiry notification, admin alerts
- Sidekiq setup for background email delivery and scheduled reminders
- Service and controller specs
- **Deliverable**: End-to-end payment flow with email notifications

### Phase 4: Admin Panel (Week 6-7)
- Devise setup for AdminUser model
- CanCanCan Ability class with role-based permissions
- Admin layout with sidebar navigation
- Dashboard with stats, upcoming bookings, recent inquiries
- Calendar management page (Stimulus interactive calendar)
- Bookings CRUD with filters, pagination, status management, refunds
- Inquiries CRUD with status management
- Property editor (details, photos with Active Storage, amenities, pricing)
- Testimonial management
- Site content editor
- Admin settings page
- Admin controller and request specs
- **Deliverable**: Full admin panel

### Phase 5: Polish & Launch (Week 8)
- SEO: meta tags, OpenGraph, JSON-LD, sitemap, robots.txt
- Performance: image variants, eager loading, caching (Russian doll caching)
- rack-attack rate limiting
- Error pages: 404, 500, 422
- Loading states and Turbo Frame placeholders
- FAQ, policies, privacy, terms pages
- Accessibility audit and fixes
- Full RSpec test suite pass, RuboCop clean
- Production deployment setup
- **Deliverable**: Production-ready launch

---

## 10. Key Gems

```ruby
# Gemfile

# Core
gem "rails", "~> 7.1"
gem "pg"
gem "puma"
gem "redis"
gem "sidekiq"

# Frontend
gem "bootstrap"
gem "sassc-rails"
gem "importmap-rails"

# Auth & Authorization
gem "devise"
gem "cancancan"

# Payments
gem "stripe"

# Image Upload
gem "image_processing"
gem "aws-sdk-s3" # or cloudinary gem

# Email
gem "resend" # or use standard SMTP

# Utilities
gem "pagy" # pagination
gem "ransack" # admin search/filters
gem "rack-attack" # rate limiting

# Development & Test
group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-performance", require: false
  gem "annotate"
  gem "pry-rails"
end

group :test do
  gem "shoulda-matchers"
  gem "capybara"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "webmock"
  gem "vcr"
end
```

---

## 11. File Structure Overview

```
colorado_rent/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── pages_controller.rb
│   │   ├── property_controller.rb
│   │   ├── availability_controller.rb
│   │   ├── bookings_controller.rb
│   │   ├── inquiries_controller.rb
│   │   ├── webhooks_controller.rb
│   │   └── admin/
│   │       ├── base_controller.rb
│   │       ├── dashboard_controller.rb
│   │       ├── calendar_controller.rb
│   │       ├── bookings_controller.rb
│   │       ├── inquiries_controller.rb
│   │       ├── property_controller.rb
│   │       ├── photos_controller.rb
│   │       ├── amenities_controller.rb
│   │       ├── seasonal_pricings_controller.rb
│   │       ├── testimonials_controller.rb
│   │       ├── content_controller.rb
│   │       └── settings_controller.rb
│   ├── models/
│   │   ├── admin_user.rb
│   │   ├── property.rb
│   │   ├── property_image.rb
│   │   ├── amenity.rb
│   │   ├── seasonal_pricing.rb
│   │   ├── availability.rb
│   │   ├── booking.rb
│   │   ├── inquiry.rb
│   │   ├── testimonial.rb
│   │   ├── site_content.rb
│   │   └── ability.rb (CanCanCan)
│   ├── services/
│   │   ├── availability_service.rb
│   │   ├── pricing_service.rb
│   │   ├── booking_service.rb
│   │   ├── stripe_checkout_service.rb
│   │   ├── stripe_webhook_service.rb
│   │   └── inquiry_service.rb
│   ├── mailers/
│   │   ├── booking_mailer.rb
│   │   ├── inquiry_mailer.rb
│   │   └── admin_mailer.rb
│   ├── jobs/
│   │   ├── booking_reminder_job.rb
│   │   └── ~~payment_reminder_job.rb~~ (removed)
│   ├── views/
│   │   ├── layouts/
│   │   ├── pages/
│   │   ├── property/
│   │   ├── availability/
│   │   ├── bookings/
│   │   ├── inquiries/
│   │   ├── shared/ (partials: _header, _footer, _flash)
│   │   └── admin/
│   ├── javascript/
│   │   └── controllers/ (Stimulus)
│   │       ├── scroll_animation_controller.js
│   │       ├── mobile_menu_controller.js
│   │       ├── counter_controller.js
│   │       ├── carousel_controller.js
│   │       ├── lightbox_controller.js
│   │       ├── calendar_controller.js
│   │       ├── booking_form_controller.js
│   │       ├── admin_calendar_controller.js
│   │       └── photo_upload_controller.js
│   └── assets/
│       ├── stylesheets/
│       │   └── application.scss
│       └── images/
├── config/
│   ├── routes.rb
│   ├── database.yml
│   ├── initializers/
│   │   ├── devise.rb
│   │   ├── stripe.rb
│   │   └── sidekiq.rb
│   └── locales/
├── db/
│   ├── migrate/
│   ├── schema.rb
│   └── seeds.rb
├── spec/
│   ├── models/
│   ├── controllers/ (request specs)
│   ├── services/
│   ├── mailers/
│   ├── jobs/
│   ├── system/
│   ├── factories/
│   ├── support/
│   └── spec_helper.rb
└── claude/
    └── docs/
        └── SRS.md (this file)
```

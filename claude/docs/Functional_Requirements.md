# Functional Requirements Document

## The Anchorpoint Retreat — Colorado Property Rental Website

**Version:** 1.0
**Date:** 2026-04-29
**Status:** Draft
**Derived From:** Software Requirements Specification (SRS) v1.0

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Public Website Requirements](#2-public-website-requirements)
3. [Payment Integration Requirements](#3-payment-integration-requirements)
4. [Admin Panel Requirements](#4-admin-panel-requirements)
5. [Email Notification Requirements](#5-email-notification-requirements)
6. [Traceability Matrix](#6-traceability-matrix)

---

## 1. Introduction

### 1.1 Purpose

This document specifies the functional requirements for The Anchorpoint Retreat, a single-property rental website for a corporate retreat and wellness property in Colorado. It is derived from the Software Requirements Specification (SRS) v1.0 and serves as the authoritative reference for development, testing, and acceptance criteria.

### 1.2 Scope

The system provides:

- A public-facing marketing and booking website for guests
- An interactive availability calendar with dynamic pricing
- A Stripe-integrated booking and payment flow
- A contact/inquiry submission system
- A protected admin panel for property, booking, and content management
- Transactional email notifications for guests and administrators

### 1.3 Definitions

| Term | Definition |
|------|-----------|
| Guest | A public visitor who browses, books, or submits inquiries |
| Admin | Property owner/manager with full system access via Devise authentication |
| Super Admin | Admin with additional user management privileges |
| Booking | A confirmed or pending reservation for specific dates |
| Inquiry | A contact form submission from a potential guest |
| Availability | Per-day status of the property: available, booked, blocked, or maintenance |
| Deposit | Partial upfront payment (configurable, default 25% of total) |
| Confirmation Number | Unique booking identifier (format: SR-YYYYMMDD-XXXX) |

---

## 2. Public Website Requirements

### FR-001: Homepage

The homepage shall serve as the primary marketing page, presenting the property and guiding guests toward booking or inquiry. It shall display the following sections in the specified order:

| # | Section | Description |
|---|---------|-------------|
| 1 | Navigation | Sticky header with logo, nav links (The Retreat, Experience, Availability, About), and "Book Your Stay" CTA button. Transparent over hero, solid white on scroll. Mobile hamburger menu. |
| 2 | Hero | Full-viewport background image/video of Colorado mountain property. Large headline, subtitle, two CTAs: "Check Availability" (primary) and "Take a Tour" (secondary/scroll). |
| 3 | Metrics Bar | Dark horizontal strip with 3–4 animated counters (retreats hosted, guest rating, max guests, property acreage). Count-up animation triggered on scroll into view. |
| 4 | Property Overview | Split layout: large image (left) + property story text with quick specs (bedrooms, bathrooms, guests, sqft) and "Explore the Property" link (right). |
| 5 | Experience Types | 3 tall portrait cards: Corporate Retreats, Wellness Retreats, Private Gatherings. Full-bleed images with gradient overlay text. Each links to /experience. |
| 6 | Photo Gallery | Asymmetric masonry grid (2 large + 3 small photos). Click opens full-screen lightbox. "+N more" indicator on last image. |
| 7 | Amenities Grid | 8 featured amenities in a 2×4 grid. Each displays icon, name, and one-line description. "View All Amenities" link below. |
| 8 | How It Works | 3 horizontal steps with icons and connecting line: Choose Your Dates → Tell Us About Your Group → Arrive and Unwind. CTA button below. |
| 9 | Testimonials | Carousel/slider of guest testimonials. Each card: quote text, guest photo, name, title/company, star rating. Prev/next navigation + dot indicators. |
| 10 | Availability CTA | Full-bleed nature image with dark overlay. Centered white text: headline "Ready to Plan Your Retreat?", subtext, and "View Availability" button. |
| 11 | Footer | 4-column layout: brand info + social links, navigation links, policy links, contact info + newsletter email signup. Bottom bar with copyright. |

---

### FR-002: Property Details Page (`/the-retreat`)

The property details page shall include:

- Full photo gallery with lightbox viewer
- Detailed property description (rich text)
- Property specifications: bedrooms, bathrooms, max guests, square footage
- Check-in/check-out times
- Full amenities list grouped by category (Wellness, Outdoor, Kitchen, Comfort, Workspace, Entertainment, Safety)
- Embedded map showing property location
- CTA to check availability

---

### FR-003: Experience Page (`/experience`)

The experience page shall present three experience types:

- Corporate Retreats
- Wellness Retreats
- Private Gatherings

Each section shall include:

- Hero image
- Description text
- Sample activities and itinerary ideas
- CTAs linking to booking or inquiry

---

### FR-004: About Page (`/about`)

The about page shall include:

- Property story and history
- Owner/host introduction with photo
- Philosophy and values
- Location highlights (nearby attractions, activities)

---

### FR-005: Availability Page (`/availability`)

The availability page shall provide:

- Interactive calendar displaying available, booked, and blocked dates
- Color coding: green = available, red = booked, gray = blocked
- Date range selection for check-in / check-out
- Dynamic price calculation on date selection showing:
  - Nightly rate(s)
  - Number of nights
  - Cleaning fee
  - Taxes
  - Total
  - Deposit amount (25%)
- Guest count selector
- "Book Now" button (enabled only when valid dates are selected)
- "Have Questions? Submit an Inquiry" link

---

### FR-006: Booking Flow

#### Step 1 — Guest Details (`/book`)

When a guest initiates booking from the availability page, the system shall present a booking form pre-populated with the selected date range and guest count.

**Required form fields:**

- Full name (required)
- Email (required, validated format)
- Phone (optional)
- Company name (optional)
- Retreat type dropdown: Corporate, Wellness, Private, Other (optional)
- Special requests (textarea, optional)

**Additional requirements:**

- Price summary sidebar showing full cost breakdown
- "Proceed to Payment" button
- Server-side validation of all inputs
- Booking record created with status "pending"

#### Step 2 — Payment (`/book/:id/payment`)

The payment page shall offer two payment options:

- "Pay Deposit (25%)" — partial payment, remainder due later
- "Pay Full Amount" — complete payment

**Payment behavior:**

- Clicking either option creates a Stripe Checkout Session and redirects to Stripe's hosted payment page
- Stripe handles all card input (PCI compliance)
- Cancel URL returns the guest to the payment page
- Checkout session expires after 30 minutes

#### Step 3 — Confirmation (`/book/:id/confirmation`)

After successful Stripe payment, the confirmation page shall display:

- Confirmation number
- Booking dates and guest count
- Amount paid
- Remaining balance (if deposit payment)
- Booking details summary
- "Add to Calendar" link (iCal download)
- Confirmation email is sent automatically

---

### FR-007: Inquiry Form (`/inquiry`)

The inquiry form shall collect:

- Name (required)
- Email (required)
- Phone (optional)
- Company (optional)
- Retreat type dropdown (optional)
- Preferred dates (free text, optional)
- Group size (number, optional)
- Message (textarea, required)

**Submission behavior:**

- Rate limited: maximum 5 submissions per IP per hour
- Creates inquiry record in the database
- Sends notification email to admin
- Redirects to thank-you page (`/inquiry/thank-you`) with confirmation message and expected response time

---

### FR-008: Static Pages

| Page | Route | Description |
|------|-------|-------------|
| FAQ | `/faq` | Accordion-style expandable Q&A items, admin-editable via content management |
| Policies | `/policies` | Cancellation policy, house rules, terms of stay |
| Privacy Policy | `/privacy` | Site privacy policy |
| Terms of Service | `/terms` | Site terms of service |

---

## 3. Payment Integration Requirements

### FR-009: Payment Processing (Stripe)

**Payment flow:**

- Integration method: Stripe Checkout Sessions (redirect-based)
- Payment types supported: Deposit (configurable %, default 25%) or full payment

**Webhook endpoint (`/webhooks/stripe`) shall handle:**

| Event | System Action |
|-------|--------------|
| `checkout.session.completed` | Update booking status to "deposit_paid" or "fully_paid"; update amount_paid; mark selected dates as "booked" in availability; send confirmation email |
| `checkout.session.expired` | Handle expired sessions appropriately |
| `charge.refunded` | Update booking status to "refunded"; release dates back to "available" |

**Security and reliability requirements:**

- Stripe webhook signature verification on all incoming requests
- Idempotency: store `stripe_session_id` to prevent double-processing
- Checkout Session metadata must include: `booking_id`, `payment_type` (deposit/full)
- Session expiration: 30 minutes
- Refunds initiated by admin from admin panel via Stripe Refunds API

---

### FR-010: Remaining Balance Collection

- For deposit-paid bookings, admin can generate a payment link for the remaining balance
- Payment link creates a new Stripe Checkout Session for the outstanding amount
- Future enhancement: automated email 30 days before check-in with payment link

---

## 4. Admin Panel Requirements

All admin routes are namespaced under `/admin` and require Devise authentication. CanCanCan enforces role-based authorization. Only authenticated users with `admin` or `super_admin` roles may access these features.

### FR-011: Admin Dashboard (`/admin`)

The dashboard shall display:

- **Stat cards:** total revenue (current month), upcoming bookings count, occupancy rate (current month), new inquiries count
- **Upcoming bookings list:** next 5 bookings with guest name, dates, status, and link to detail
- **Recent inquiries list:** last 5 inquiries with name, date, and status
- **Quick actions:** block dates, view calendar, export bookings as CSV

---

### FR-012: Calendar Management (`/admin/calendar`)

The admin calendar shall provide:

- Full month-view calendar grid
- Color-coded dates: green (available), red (booked), gray (blocked), yellow (pending)
- Click a single date to toggle available/blocked
- Click + drag or shift-click to select a date range, then bulk-set status
- Clicking a booked date shows booking details in a sidebar/modal
- Per-date price override capability
- Month navigation (previous/next)

---

### FR-013: Booking Management (`/admin/bookings`)

**Booking list view:**

- Paginated table of all bookings
- Filters: status dropdown, date range, search by guest name/email
- Sortable columns: check-in date, status, total, created date
- Columns: confirmation #, guest name, check-in, check-out, guests, total, status, actions

**Booking detail view (`/admin/bookings/:id`):**

- Full guest information and booking details
- Payment history (amount paid, payment method, Stripe links)
- Status update actions: confirm, cancel, mark checked-in, mark completed
- Admin notes field (internal, not visible to guest)
- Refund action (partial or full, triggers Stripe refund)
- Send payment reminder email action
- Send custom email to guest
- CSV export of all bookings

---

### FR-014: Inquiry Management (`/admin/inquiries`)

**Inquiry list view:**

- Paginated table: name, email, retreat type, date submitted, status
- Filters: status (new, responded, closed)

**Inquiry detail view (`/admin/inquiries/:id`):**

- Full inquiry details
- Status workflow: new → responded → closed
- Admin notes field
- Quick reply via email (opens mailer with guest's email)

---

### FR-015: Property Management (`/admin/property`)

#### Details Tab

Editable fields:

- Property name, tagline, description (rich text)
- Address, city, zip, coordinates (latitude/longitude)
- Bedrooms, bathrooms, max guests, square footage
- Check-in and check-out times

#### Photos Tab

- Drag-and-drop image upload via Active Storage
- Sortable grid with drag handles
- Category assignment per photo: Hero, Exterior, Interior, Bedroom, Bathroom, Kitchen, Living, Outdoor, Amenity, Aerial
- Alt text editing for each image
- Delete with confirmation dialog

#### Amenities Tab

- Full CRUD for amenities
- Fields: name, description, icon selection (Lucide icon), category (Wellness, Outdoor, Kitchen, Comfort, Workspace, Entertainment, Safety)
- Featured toggle (controls homepage display)
- Drag-to-reorder

#### Pricing Tab

- Base price per night (stored in cents)
- Cleaning fee (stored in cents)
- Deposit percentage
- Minimum and maximum nights
- Seasonal pricing table: add/edit/delete date ranges with custom nightly rate and optional minimum-night override

---

### FR-016: Testimonial Management (`/admin/testimonials`)

CRUD operations for testimonials with the following fields:

- Author name
- Author title/company
- Author photo upload
- Quote text
- Rating (1–5)
- Retreat type
- Featured toggle
- Sort order

---

### FR-017: Site Content Management (`/admin/content`)

A key-value editor for editable site text, allowing the admin to update the following content without code changes:

- Hero headline and hero subtitle
- About section text
- Experience section descriptions
- Metrics bar values and labels
- FAQ items (question + answer pairs)
- Markdown support for longer text blocks

---

### FR-018: Admin Settings (`/admin/settings`)

- Update admin account email and password
- Notification preferences (email on new booking, new inquiry)
- Super admin only: manage other admin users (invite, deactivate)

---

## 5. Email Notification Requirements

### FR-019: Transactional Emails

All emails shall be sent via Action Mailer with Sidekiq for background delivery.

| Email | Trigger | Recipient | Content |
|-------|---------|-----------|---------|
| Booking Confirmation | Successful payment webhook | Guest | Confirmation #, dates, amount paid, property details, check-in instructions |
| Booking Reminder | 7 days before check-in (Sidekiq scheduled job) | Guest | Upcoming stay reminder, check-in time, directions |
| Payment Reminder | Admin-triggered or 30 days before check-in | Guest | Outstanding balance, payment link |
| Inquiry Received | Inquiry form submitted | Guest | Thank-you message, expected response time |
| New Inquiry Alert | Inquiry form submitted | Admin | Inquiry details, link to admin panel |
| New Booking Alert | Booking created | Admin | Booking details, link to admin panel |
| Cancellation Notice | Booking cancelled | Guest | Cancellation confirmation, refund details |

---

## 6. Traceability Matrix

The following matrix maps each functional requirement to its SRS source section and priority level.

| Requirement ID | Title | SRS Section | Priority |
|----------------|-------|-------------|----------|
| FR-001 | Homepage | 4.1 | High |
| FR-002 | Property Details Page | 4.1 | High |
| FR-003 | Experience Page | 4.1 | Medium |
| FR-004 | About Page | 4.1 | Medium |
| FR-005 | Availability Page | 4.1 | High |
| FR-006 | Booking Flow | 4.1 | Critical |
| FR-007 | Inquiry Form | 4.1 | High |
| FR-008 | Static Pages | 4.1 | Low |
| FR-009 | Payment Processing | 4.2 | Critical |
| FR-010 | Remaining Balance Collection | 4.2 | Medium |
| FR-011 | Admin Dashboard | 4.3 | High |
| FR-012 | Calendar Management | 4.3 | High |
| FR-013 | Booking Management | 4.3 | High |
| FR-014 | Inquiry Management | 4.3 | Medium |
| FR-015 | Property Management | 4.3 | High |
| FR-016 | Testimonial Management | 4.3 | Low |
| FR-017 | Site Content Management | 4.3 | Medium |
| FR-018 | Admin Settings | 4.3 | Medium |
| FR-019 | Transactional Emails | 4.4 | High |

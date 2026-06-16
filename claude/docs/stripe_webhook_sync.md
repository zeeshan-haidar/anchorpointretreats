# Stripe Webhook Sync — Booking Reconciliation

## Flow Overview

```
Guest pays on Stripe Checkout
          │
          ├─────────────────────────────────────┐
          │                                     │
          ▼                                     ▼
  Stripe redirects guest              Stripe fires webhook
  to /book/:id/confirmation           to /webhooks/stripe
          │                                     │
          ▼                                     ▼
  confirmation action runs            StripeWebhookService
          │                             processes event
          ▼                                     │
  Is booking still pending?            ┌────────┴────────┐
          │                            │                 │
          ├── No → show page          │                 │
          │                            │                 │
          └── Yes → sync_with_stripe!  │                 │
                      │                │                 │
                      ▼                ▼                 ▼
               Queries Stripe API   Updates booking   Marks availability
               directly to check    to fully_paid     as booked
               if session was paid
                      │                │                 │
                      ▼                ▼                 ▼
               If paid: updates      Sends confirmation email to guest
               booking, marks
               availability, sends
               email (same as webhook)

  ✅ Either path results in: booking = fully_paid, dates = booked, email = sent
```

## Problem

When a guest pays via Stripe Checkout, the normal flow is:

1. User submits payment on Stripe → redirected to `/book/:id/confirmation`
2. Stripe sends a `checkout.session.completed` webhook to `/webhooks/stripe`
3. The webhook updates the booking to `fully_paid`, records `amount_paid_cents`, and sends the confirmation email

**If the webhook fails** (network issue, server restart, timeout, etc.), the booking remains stuck as `pending` — even though the payment succeeded on Stripe's end. The guest lands on the confirmation page seeing an unpaid booking, and the admin sees no record of payment.

## Solution: `sync_with_stripe!`

A method on the `Booking` model that reconciles the booking's status with Stripe by checking the actual Checkout Session state.

### Method

```ruby
# app/models/booking.rb
def sync_with_stripe!
  return false unless stripe_checkout_session_id.present?
  return false unless pending?

  session = Stripe::Checkout::Session.retrieve(stripe_checkout_session_id)
  return false unless session.payment_status == "paid"

  ActiveRecord::Base.transaction do
    update!(
      status: :fully_paid,
      amount_paid_cents: session.amount_total,
      stripe_payment_intent_id: session.payment_intent
    )

    # Mark availability dates as booked
    AvailabilityService.new(property).mark_booked(
      check_in: check_in,
      check_out: check_out,
      booking: self
    )
  end

  BookingMailer.confirmation(self).deliver_later

  true
rescue Stripe::StripeError => e
  Rails.logger.warn "[Booking##{id}] Stripe sync failed: #{e.message}"
  false
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.warn "[Booking##{id}] Stripe sync succeeded but failed to mark availability: #{e.message}"
  false
end
```

### How it works

1. **Checks preconditions** — only runs if the booking has a `stripe_checkout_session_id` and is currently `pending`
2. **Queries Stripe API** — retrieves the Checkout Session to see if payment was actually completed
3. **Updates if paid** — sets status to `fully_paid`, records the amount paid and payment intent ID
4. **Marks availability** — calls `AvailabilityService#mark_booked` to lock the dates (same as the webhook)
5. **Sends confirmation email** — delivers `BookingMailer.confirmation` (same as the webhook)
6. **All in a transaction** — ensures booking update and availability marking happen atomically
7. **Logs failures** — logs warnings but never raises exceptions

> ⚠️ `sync_with_stripe!` is a **complete replacement** for the webhook. If it runs and succeeds, the late-arriving webhook will see the booking is no longer `pending` and safely skip (idempotency guard in `StripeWebhookService`).

## Automatic Fallback

The `confirmation` action in `BookingsController` calls `sync_with_stripe!` before showing the page:

```ruby
# app/controllers/bookings_controller.rb
def confirmation
  redirect_to availability_path, alert: "Booking not found" unless @booking

  # Fallback: if the booking is still pending but has a Stripe session,
  # try to sync with Stripe (handles missed webhooks)
  if @booking.pending? && @booking.stripe_checkout_session_id.present?
    synced = @booking.sync_with_stripe!
    if synced
      flash.now[:notice] = "Payment confirmed! Your booking is all set."
    end
  end

  # Only show confirmation for paid bookings.
  # If they have a Stripe session but sync didn't work yet (still processing),
  # let them stay on the confirmation page rather than redirecting to payment.
  if @booking.pending? && @booking.amount_paid_cents.zero? && !@booking.stripe_checkout_session_id.present?
    redirect_to booking_payment_path(@booking), alert: "Please complete payment first."
  end
end
```

This means even if the webhook never fires, the guest arriving at the confirmation page will see their booking correctly updated.

## Manual Usage (Rails Console)

### Single booking (safe)

```ruby
booking = Booking.find_by(confirmation_number: "AP-20260511-A1B2")
booking.sync_with_stripe!
# => true if updated, false if not
```

### Dry-run (check without updating)

```ruby
booking = Booking.find_by(confirmation_number: "AP-20260511-A1B2")
session = Stripe::Checkout::Session.retrieve(booking.stripe_checkout_session_id)
puts "Payment status: #{session.payment_status}"
puts "Amount total: #{session.amount_total}"
puts "Payment intent: #{session.payment_intent}"
```

### ⚠️ Batch backfill — inspect first, don't blindly sync

Running `sync_with_stripe!` in a loop over all pending bookings is **not recommended** because:

1. **Overlapping dates** — If two pending bookings have overlapping date ranges and both were actually paid, this means the property was double-booked. Running `sync_with_stripe!` on both would mark both sets of dates as booked, silently accepting the double-booking.
2. **Stale sessions** — Pending bookings might have old/expired Stripe sessions that show as `unpaid`. The sync would skip them, but the loop gives a false sense of "all cleaned up."

**Better approach**: Inspect first, then fix one by one.

```ruby
# Step 1: Inspect — find stuck bookings and check their Stripe status
Booking.pending.where.not(stripe_checkout_session_id: nil).each do |booking|
  session = Stripe::Checkout::Session.retrieve(booking.stripe_checkout_session_id)
  puts "#{booking.confirmation_number}: payment_status=#{session.payment_status}, dates=#{booking.check_in}–#{booking.check_out}"
end

# Step 2: Fix individually after manual review
booking = Booking.find_by(confirmation_number: "AP-20260511-XXXX")
booking.sync_with_stripe!
```

## Limitations

- Only handles **full payment** scenarios (deposit flow has been removed)
- Only works for bookings that have a `stripe_checkout_session_id` stored
- **Not safe for blind batch backfill** — see Manual Usage section above. Always inspect before syncing multiple bookings to avoid silently confirming double-bookings.

## Architecture Note

| Layer | Responsibility |
|---|---|
| **Stripe webhook** (`StripeWebhookService`) | **Primary path** — updates booking, marks availability, sends confirmation email |
| **`sync_with_stripe!` method** | **Fallback** — exactly the same operations as the webhook (transactional update + availability marking + email) |
| **Confirmation controller** | **Trigger** — calls `sync_with_stripe!` on page load if the booking is still pending with a Stripe session |

### Idempotency

Both paths are safe to run simultaneously or in sequence:

| Scenario | Result |
|---|---|
| Webhook arrives first, then sync runs | Sync sees `status` is no longer `pending` → skips (returns false) |
| Sync runs first, then webhook arrives | Webhook sees `booking.pending?` is false → returns "already processed" (idempotent guard) |
| Webhook never arrives | Sync handles everything — booking is updated, availability is marked, email is sent |

This is a defense-in-depth approach. The webhook remains the primary mechanism; `sync_with_stripe!` covers the gap transparently.

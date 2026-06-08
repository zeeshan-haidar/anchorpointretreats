# app/services/availability_service.rb
require "ostruct"
# Fetches available dates, checks date ranges, and manages availability status.
class AvailabilityService
  def initialize(property)
    @property = property
  end

  # Returns availability data for a given month (year/month params)
  # Used by the calendar JSON endpoint
  def calendar_data(year:, month:)
    start_date = Date.new(year.to_i, month.to_i, 1)
    end_date = start_date.end_of_month

    availabilities = @property.availabilities.for_range(start_date, end_date).ordered

    # Build a hash keyed by date for fast lookup
    availability_hash = availabilities.each_with_object({}) do |a, hash|
      hash[a.date] = { status: a.status, price_override: a.price_override_cents }
    end

    # Fill in missing dates as available (with no override)
    (start_date..end_date).map do |date|
      entry = availability_hash[date] || { status: "available", price_override: nil }
      {
        date: date,
        status: entry[:status],
        price_override: entry[:price_override],
        day: date.day,
        month: date.month,
        year: date.year,
        past: date < Date.current
      }
    end
  end

  # Checks if a continuous date range is fully available (not booked/blocked)
  # Returns true/false
  def available_for_range?(check_in, check_out)
    dates = (check_in...check_out).to_a
    return false if dates.empty?

    # Get any availabilities that conflict with the requested range
    conflicting = @property.availabilities
                           .for_range(check_in, check_out)
                           .where.not(status: :available)
                           .pluck(:date)
                           .to_set

    # If any date in range is unavailable, the range is not available
    dates.none? { |date| conflicting.include?(date) }
  end

  # Returns available dates between start_date and end_date
  def available_dates(check_in, check_out)
    dates = (check_in...check_out).to_a
    conflicting = @property.availabilities
                           .for_range(check_in, check_out)
                           .where.not(status: :available)
                           .pluck(:date)
                           .to_set

    dates.reject { |date| conflicting.include?(date) }
  end

  # Marks a set of dates as booked (linked to a booking)
  def mark_booked(check_in:, check_out:, booking:)
    dates = (check_in...check_out).to_a
    dates.each do |date|
      availability = @property.availabilities.find_or_initialize_by(date: date)
      availability.update!(status: :booked, booking_id: booking.id)
    end
  end

  # Marks a set of dates as available (releases them)
  def mark_available(check_in:, check_out:)
    dates = (check_in...check_out).to_a
    @property.availabilities.for_range(check_in, check_out).update_all(
      status: :available, booking_id: nil
    )
  end
end

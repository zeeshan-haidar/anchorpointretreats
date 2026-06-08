# app/services/pricing_service.rb
require "ostruct"
# Calculates total price breakdown for a booking based on dates, guest count,
# base price, seasonal pricing overrides, cleaning fee, and taxes.
class PricingService
  TAX_RATE = 0.085 # 8.5% tax rate for Colorado

  def initialize(property)
    @property = property
  end

  # Calculates a full price breakdown
  # Returns an OpenStruct with success? and price details or error
  def call(check_in:, check_out:, num_guests:)
    return OpenStruct.new(success?: false, error: "Property not found") unless @property
    return OpenStruct.new(success?: false, error: "Check-out must be after check-in") if check_out <= check_in
    return OpenStruct.new(success?: false, error: "Guest count exceeds maximum") if num_guests.to_i > @property.max_guests

    num_nights = (check_out - check_in).to_i

    return OpenStruct.new(success?: false, error: "Minimum stay is #{@property.min_nights} nights") if num_nights < @property.min_nights
    return OpenStruct.new(success?: false, error: "Maximum stay is #{@property.max_nights} nights") if num_nights > @property.max_nights

    nightly_rate = calculate_nightly_rate(check_in, check_out)
    subtotal = nightly_rate * num_nights
    cleaning_fee = @property.cleaning_fee_cents
    taxes = ((subtotal + cleaning_fee) * TAX_RATE).round
    total = subtotal + cleaning_fee + taxes
    deposit = (total * @property.deposit_percentage / 100.0).round

    OpenStruct.new(
      success?: true,
      nightly_rate_cents: nightly_rate,
      num_nights: num_nights,
      subtotal_cents: subtotal,
      cleaning_fee_cents: cleaning_fee,
      taxes_cents: taxes,
      total_cents: total,
      deposit_amount_cents: deposit,
      balance_due_cents: total - deposit,
      min_nights: @property.min_nights,
      max_nights: @property.max_nights,
      max_guests: @property.max_guests
    )
  end

  private

  # Determines the effective nightly rate, accounting for seasonal pricing overrides
  # For date ranges spanning multiple seasonal periods, uses the average rate
  def calculate_nightly_rate(check_in, check_out)
    seasonal_pricings = @property.seasonal_pricings.ordered

    if seasonal_pricings.any?
      # Calculate weighted average nightly rate across the stay
      total_nights = (check_out - check_in).to_i
      total_cost = 0

      (check_in...check_out).each do |date|
        seasonal = seasonal_pricings.find { |sp| sp.start_date <= date && sp.end_date >= date }
        if seasonal
          total_cost += seasonal.price_per_night_cents
        else
          total_cost += @property.base_price_cents
        end
      end

      (total_cost.to_f / total_nights).round
    else
      @property.base_price_cents
    end
  end
end

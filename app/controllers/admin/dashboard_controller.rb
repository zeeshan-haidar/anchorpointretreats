# app/controllers/admin/dashboard_controller.rb
# GET /admin

module Admin
  class DashboardController < BaseController
    authorize_resource :class => false

    # GET /admin
    def index
      @stats = dashboard_stats
      @upcoming_bookings = Booking.upcoming.includes(:property).limit(5)
      @recent_inquiries = Inquiry.order(created_at: :desc).limit(5)
    end

    private

    def dashboard_stats
      today = Date.current
      first_of_month = today.beginning_of_month

      monthly_revenue_cents = Booking.where(status: :fully_paid)
                                     .where("updated_at >= ?", first_of_month)
                                     .sum(:amount_paid_cents)

      upcoming_count = Booking.upcoming.count

      property = Property.first
      total_days_in_month = Time.days_in_month(today.month, today.year)
      booked_days = if property
                      property.availabilities
                              .where(date: first_of_month..today.end_of_month, status: :booked)
                              .count
                    else
                      0
                    end
      occupancy_rate = total_days_in_month > 0 ? (booked_days.to_f / total_days_in_month * 100).round(1) : 0

      new_inquiries_count = Inquiry.where(status: :new_inquiry).count

      last_month = first_of_month - 1.month
      last_month_end = first_of_month - 1.day
      last_month_revenue = Booking.where(status: :fully_paid)
                                  .where("updated_at >= ? AND updated_at <= ?", last_month, last_month_end)
                                  .sum(:amount_paid_cents)
      revenue_change = if last_month_revenue > 0
                         (((monthly_revenue_cents - last_month_revenue).to_f / last_month_revenue) * 100).round(1)
                       else
                         0
                       end

      last_month_bookings = Booking.where("created_at >= ? AND created_at <= ?", last_month, last_month_end).count
      this_month_bookings = Booking.where("created_at >= ?", first_of_month).count
      booking_change = if last_month_bookings > 0
                         (((this_month_bookings - last_month_bookings).to_f / last_month_bookings) * 100).round(1)
                       else
                         0
                       end

      OpenStruct.new(
        monthly_revenue_cents: monthly_revenue_cents,
        revenue_change: revenue_change,
        upcoming_count: upcoming_count,
        booking_change: booking_change,
        occupancy_rate: occupancy_rate,
        new_inquiries_count: new_inquiries_count
      )
    end
  end
end

# app/controllers/admin/calendar_controller.rb
# GET /admin/calendar

module Admin
  class CalendarController < BaseController
    skip_authorization_check

    # GET /admin/calendar
    def index
      @property = Property.first
      @year = (params[:year] || Date.current.year).to_i
      @month = (params[:month] || Date.current.month).to_i
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month

      @availabilities = @property.availabilities
                                  .where(date: @start_date..@end_date)
                                  .index_by(&:date)
    end

    # PATCH /admin/calendar/:id
    def update
      @property = Property.first
      date = Date.parse(params[:id])
      new_status = params[:status]

      unless %w[available blocked].include?(new_status)
        redirect_to admin_calendar_index_path, alert: "Invalid status." and return
      end

      availability = @property.availabilities.find_or_create_by!(date: date)

      if availability.booked?
        redirect_to admin_calendar_index_path(year: date.year, month: date.month),
                    alert: "Cannot update a booked date. Cancel or refund the booking first."
        return
      end

      availability.update!(status: new_status, booking_id: nil)
      redirect_to admin_calendar_index_path(year: date.year, month: date.month), notice: "Date updated."
    end

    # POST /admin/calendar/bulk_update
    def bulk_update
      @property = Property.first
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      new_status = params[:status]

      unless %w[available blocked].include?(new_status)
        redirect_to admin_calendar_index_path, alert: "Invalid status." and return
      end

      (start_date..end_date).each do |date|
        availability = @property.availabilities.find_or_create_by!(date: date)
        unless availability.booked?
          availability.update!(status: new_status, booking_id: nil)
        end
      end

      redirect_to admin_calendar_index_path(year: start_date.year, month: start_date.month),
                  notice: "Dates updated successfully."
    end
  end
end

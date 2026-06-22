# app/controllers/admin/bookings_controller.rb
# CRUD for bookings
require "csv"

module Admin
  class BookingsController < BaseController
    # GET /admin/bookings
    load_and_authorize_resource

    # GET /admin/bookings
    def index
      @q = Booking.ransack(params[:q])
      @bookings = @q.result
                     .includes(:property)
                     .order(created_at: :desc)

      @pagy, @bookings = pagy(:offset, @bookings, limit: 20)
    end

    # GET /admin/bookings/:id
    def show
    end

    # PATCH /admin/bookings/:id
    def update
      if @booking.update(booking_params)
        redirect_to admin_booking_path(@booking), notice: "Booking updated successfully."
      else
        flash.now[:alert] = "Failed to update booking: #{@booking.errors.full_messages.join(', ')}"
        render :show, status: :unprocessable_content
      end
    end

    # POST /admin/bookings/:id/refund
    def refund
      if @booking.amount_paid_cents <= 0
        redirect_to admin_booking_path(@booking), alert: "No payment to refund." and return
      end

      refund_amount_cents = @booking.amount_paid_cents

      begin
        if @booking.stripe_payment_intent_id.present?
          Stripe::Refund.create(payment_intent: @booking.stripe_payment_intent_id)
        end

        @booking.availabilities.update_all(status: :available, booking_id: nil)

        @booking.update!(
          status: :refunded,
          amount_paid_cents: 0,
          admin_notes: (@booking.admin_notes.to_s + "\n[#{Time.current.strftime("%Y-%m-%d %H:%M")}] Refunded via admin panel. Refund email sent.").strip
        )

        BookingMailer.refund_confirmation(@booking, refund_amount_cents: refund_amount_cents).deliver_later

        redirect_to admin_booking_path(@booking), notice: "Booking refunded successfully."
      rescue Stripe::StripeError => e
        redirect_to admin_booking_path(@booking), alert: "Refund failed: #{e.message}"
      end
    end

    # GET /admin/bookings/export.csv
    def export
      @bookings = Booking.includes(:property).order(created_at: :desc)
      respond_to do |format|
        format.csv do
          headers = %w[ConfirmationNumber GuestName GuestEmail GuestPhone CompanyName
                       CheckIn CheckOut NumGuests RetreatType NumNights
                       NightlyRate Subtotal CleaningFee Taxes Total AmountPaid
                       Status CreatedAt AdminNotes]
          csv_data = CSV.generate(headers: true) do |csv|
            csv << headers
            @bookings.each do |b|
              csv << [b.confirmation_number, b.guest_name, b.guest_email, b.guest_phone,
                      b.company_name, b.check_in, b.check_out, b.num_guests, b.retreat_type,
                      b.num_nights, b.nightly_rate_cents, b.subtotal_cents,
                      b.cleaning_fee_cents, b.taxes_cents, b.total_cents,
                      b.amount_paid_cents, b.status, b.created_at, b.admin_notes]
            end
          end
          send_data csv_data, filename: "bookings-#{Date.current}.csv"
        end
      end
    end

    private

    def booking_params
      params.require(:booking).permit(:status, :admin_notes, :guest_name, :guest_email,
                                       :guest_phone, :company_name, :retreat_type,
                                       :special_requests, :num_guests)
    end
  end
end

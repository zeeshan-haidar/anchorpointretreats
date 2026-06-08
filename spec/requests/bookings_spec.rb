require "rails_helper"

RSpec.describe "BookingsController", type: :request do
  let!(:property) { FactoryBot.create(:property) }
  let(:check_in) { Date.current + 30.days }
  let(:check_out) { check_in + 3.days }

  before do
    (check_in...check_out).each do |date|
      FactoryBot.create(:availability, property: property, date: date, status: :available)
    end
  end

  describe "GET /book" do
    context "with valid date params" do
      it "returns http success" do
        get "/book", params: { check_in: check_in, check_out: check_out, num_guests: 4 }
        expect(response).to have_http_status(:success)
      end
    end

    context "without date params" do
      it "redirects to availability page" do
        get "/book"
        expect(response).to redirect_to(availability_path)
      end
    end

    context "with unavailable dates" do
      let(:bad_check_in) { Date.current + 60.days }
      let(:bad_check_out) { bad_check_in + 3.days }

      before do
        (bad_check_in...bad_check_out).each_with_index do |date, idx|
          status = idx == 1 ? :booked : :available
          FactoryBot.create(:availability, property: property, date: date, status: status)
        end
      end

      it "redirects to availability page" do
        get "/book", params: { check_in: bad_check_in, check_out: bad_check_out, num_guests: 4 }
        expect(response).to redirect_to(availability_path)
      end
    end
  end

  describe "POST /book" do
    let(:valid_params) do
      {
        check_in: check_in,
        check_out: check_out,
        num_guests: 4,
        booking: {
          guest_name: "John Doe",
          guest_email: "john@example.com",
          guest_phone: "(555) 123-4567",
          company_name: "Acme Corp",
          retreat_type: "corporate",
          special_requests: "Looking forward to it!"
        }
      }
    end

    context "with valid params" do
      it "creates a booking" do
        expect do
          post "/book", params: valid_params
        end.to change(Booking, :count).by(1)
      end

      it "redirects to payment page" do
        post "/book", params: valid_params
        booking = Booking.last
        expect(response).to redirect_to(booking_payment_path(booking))
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        valid_params.deep_merge(booking: { guest_name: "" })
      end

      it "does not create a booking" do
        expect do
          post "/book", params: invalid_params
        end.not_to change(Booking, :count)
      end

      it "renders new with unprocessable entity status" do
        post "/book", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /book/:id/payment" do
    let(:booking) { FactoryBot.create(:booking, property: property) }

    it "returns http success" do
      get booking_payment_path(booking)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /book/:id/confirmation" do
    let(:booking) { FactoryBot.create(:booking, property: property) }

    it "returns http success" do
      get booking_confirmation_path(booking)
      expect(response).to have_http_status(:success)
    end
  end
end

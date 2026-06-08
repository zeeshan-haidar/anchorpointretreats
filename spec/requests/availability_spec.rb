require "rails_helper"

RSpec.describe "AvailabilityController", type: :request do
  let!(:property) { FactoryBot.create(:property) }

  describe "GET /availability" do
    it "returns http success" do
      get "/availability"
      expect(response).to have_http_status(:success)
    end

    it "renders the index template" do
      get "/availability"
      expect(response).to render_template(:index)
    end
  end

  describe "GET /availability/calendar" do
    it "returns JSON with calendar data" do
      get "/availability/calendar", params: { year: Date.current.year, month: Date.current.month }
      expect(response).to have_http_status(:success)
      json = response.parsed_body
      expect(json).to have_key("days")
      expect(json).to have_key("year")
      expect(json).to have_key("month")
    end
  end

  describe "GET /availability/pricing" do
    let(:check_in) { Date.current + 30.days }
    let(:check_out) { check_in + 3.days }

    it "returns JSON with pricing data" do
      get "/availability/pricing",
          params: { check_in: check_in, check_out: check_out, num_guests: 4 }
      expect(response).to have_http_status(:success)
      json = response.parsed_body
      expect(json).to have_key("nightly_rate_cents")
      expect(json).to have_key("total_cents")
    end

    it "returns error for invalid dates" do
      get "/availability/pricing",
          params: { check_in: "invalid", check_out: check_out, num_guests: 4 }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

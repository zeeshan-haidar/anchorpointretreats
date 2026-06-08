require "rails_helper"

RSpec.describe "InquiriesController", type: :request do
  describe "GET /inquiry" do
    it "returns http success" do
      get "/inquiry"
      expect(response).to have_http_status(:success)
    end

    it "renders the new template" do
      get "/inquiry"
    end
  end

  describe "POST /inquiry" do
    let(:valid_params) do
      {
        inquiry: {
          name: "Jane Smith",
          email: "jane@example.com",
          phone: "(555) 987-6543",
          company: "Wellness Co.",
          retreat_type: "wellness",
          preferred_dates: "August 2026",
          group_size: 8,
          message: "We're interested in booking a wellness retreat."
        }
      }
    end

    context "with valid params" do
      it "creates an inquiry" do
        expect do
          post "/inquiry", params: valid_params
        end.to change(Inquiry, :count).by(1)
      end

      it "redirects to thank you page" do
        post "/inquiry", params: valid_params
        expect(response).to redirect_to(inquiry_thank_you_path)
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        { inquiry: { name: "", email: "invalid", message: "" } }
      end

      it "does not create an inquiry" do
        expect do
          post "/inquiry", params: invalid_params
        end.not_to change(Inquiry, :count)
      end

      it "renders new with unprocessable entity status" do
        post "/inquiry", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /inquiry/thank-you" do
    it "returns http success" do
      get "/inquiry/thank-you"
      expect(response).to have_http_status(:success)
    end

    it "renders the thank_you template" do
      get "/inquiry/thank-you"
    end
  end
end

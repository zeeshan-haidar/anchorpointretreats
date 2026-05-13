require 'rails_helper'

RSpec.describe "PagesController", type: :request do
  describe "GET /" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /the-retreat" do
    it "returns http success" do
      get "/the-retreat"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /experience" do
    it "returns http success" do
      get "/experience"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /about" do
    it "returns http success" do
      get "/about"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /faq" do
    it "returns http success" do
      get "/faq"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /policies" do
    it "returns http success" do
      get "/policies"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /privacy" do
    it "returns http success" do
      get "/privacy"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /terms" do
    it "returns http success" do
      get "/terms"
      expect(response).to have_http_status(:success)
    end
  end
end

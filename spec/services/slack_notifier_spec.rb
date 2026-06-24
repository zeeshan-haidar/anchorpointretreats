# frozen_string_literal: true

require "rails_helper"

RSpec.describe SlackNotifier, type: :service do
  let(:webhook_url) { "https://hooks.slack.com/services/test/test/test" }

  # Helper to stub specific ENV.fetch keys while allowing all others to pass through
  def stub_env_fetch(stubs = {})
    original_fetch = ENV.method(:fetch)
    allow(ENV).to receive(:fetch) do |key, *default|
      if stubs.key?(key)
        stubs[key]
      else
        original_fetch.call(key, *default)
      end
    end
  end

  describe "#initialize" do
    it "sets the title and default channel" do
      notifier = SlackNotifier.new("Test Alert")
      expect(notifier.instance_variable_get(:@title)).to eq("Test Alert")
      expect(notifier.instance_variable_get(:@channel)).to eq("#general")
    end

    it "allows overriding the channel" do
      notifier = SlackNotifier.new("Test Alert", channel: "#alerts")
      expect(notifier.instance_variable_get(:@channel)).to eq("#alerts")
    end
  end

  describe "#post" do
    context "when webhook URL is not configured" do
      before do
        # Stub only the specific call; fallback to original for all other ENV.fetch calls
        stub_env_fetch("SLACK_WEBHOOK_URL" => nil)
      end

      it "returns failure without making an HTTP request" do
        notifier = SlackNotifier.new("Test")
        result = notifier.post("Something happened")

        expect(result.success?).to be false
        expect(result.error).to eq("Webhook URL not configured")
      end
    end

    context "when webhook URL is configured" do
      before do
        stub_env_fetch("SLACK_WEBHOOK_URL" => webhook_url)
        # Stub the HTTP request to avoid actual network calls
        WebMock.reset!
        WebMock.stub_request(:post, webhook_url)
               .to_return(status: 200, body: "ok")
      end

      it "sends a notification successfully" do
        notifier = SlackNotifier.new("Test Alert")
        result = notifier.post("Something happened", fields: { "Error" => "TestError" })

        expect(result.success?).to be true
      end

      it "sends a JSON payload with expected structure" do
        notifier = SlackNotifier.new("Test Alert")
        notifier.post("Something happened")

        assert_requested(:post, webhook_url) { |req|
          body = JSON.parse(req.body)
          expect(body["channel"]).to eq("#general")
          expect(body["username"]).to eq("Anchorpoint Bot")
          expect(body["attachments"]).to be_a(Array)
          expect(body["attachments"].first["title"]).to eq("Test Alert")
          expect(body["attachments"].first["text"]).to eq("Something happened")
        }
      end

      it "includes field data in the payload" do
        notifier = SlackNotifier.new("Test Alert")
        notifier.post("Error occurred", fields: { "Error" => "NoMethodError", "File" => "test.rb" })

        assert_requested(:post, webhook_url) { |req|
          body = JSON.parse(req.body)
          fields = body["attachments"].first["fields"]
          expect(fields).to be_a(Array)
          expect(fields.map { |f| f["title"] }).to include("Error", "File")
        }
      end

      context "when Slack API returns an error" do
        before do
          WebMock.stub_request(:post, webhook_url)
                 .to_return(status: 400, body: "invalid_payload")
        end

        it "returns failure" do
          notifier = SlackNotifier.new("Test Alert")
          result = notifier.post("Something happened")

          expect(result.success?).to be false
          expect(result.error).to include("Slack API error")
        end
      end

      context "when the request times out" do
        before do
          WebMock.stub_request(:post, webhook_url).to_timeout
        end

        it "returns failure with timeout message" do
          notifier = SlackNotifier.new("Test Alert")
          result = notifier.post("Something happened")

          expect(result.success?).to be false
          expect(result.error).to include("Timeout")
        end
      end
    end
  end
end

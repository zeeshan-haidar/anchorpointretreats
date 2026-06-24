# frozen_string_literal: true

require "rails_helper"

RSpec.describe SidekiqErrorHandler, type: :service do
  let(:handler) { described_class.new }
  let(:worker) { double('TestWorker', class: 'TestWorker') }
  let(:job) { { "jid" => "abc123", "args" => [1, 2, 3], "retry_count" => 1 } }
  let(:queue) { "default" }

  describe "#call" do
    context "when the job succeeds" do
      it "yields control to the job" do
        expect { |b| handler.call(worker, job, queue, &b) }.to yield_control
      end

      it "does not notify Slack" do
        expect_any_instance_of(SlackNotifier).not_to receive(:post)

        handler.call(worker, job, queue) { "success" }
      end
    end

    context "when the job raises an exception" do
      let(:exception) { StandardError.new("Something went wrong") }

      it "re-raises the exception after handling" do
        expect {
          handler.call(worker, job, queue) { raise exception }
        }.to raise_error(StandardError, "Something went wrong")
      end

      it "notifies Slack about the failure" do
        slack_notifier_instance = instance_double(SlackNotifier)
        expect(SlackNotifier).to receive(:new)
          .with(anything, hash_including(channel: "#alerts"))
          .and_return(slack_notifier_instance)
        expect(slack_notifier_instance).to receive(:post)
          .with(anything, hash_including(:fields, :color))

        expect {
          handler.call(worker, job, queue) { raise exception }
        }.to raise_error(StandardError)
      end
    end

    context "when a job runs slowly (over 30 seconds)" do
      it "sends a slow job warning to Slack" do
        started_at = Time.current

        # Stub Time.current to simulate a long-running job
        allow(Time).to receive(:current).and_return(started_at, started_at + 31.seconds)

        slack_notifier_instance = instance_double(SlackNotifier)
        expect(SlackNotifier).to receive(:new)
          .with("Slow Job Alert", channel: "#alerts")
          .and_return(slack_notifier_instance)
        expect(slack_notifier_instance).to receive(:post)
          .with(anything, hash_including(:fields, :color))

        handler.call(worker, job, queue) { "done" }
      end
    end

    context "when a job runs within normal time (under 30 seconds)" do
      it "does not send a slow job warning" do
        expect(SlackNotifier).not_to receive(:new).with("Slow Job Alert", anything)

        handler.call(worker, job, queue) { "done" }
      end
    end
  end
end

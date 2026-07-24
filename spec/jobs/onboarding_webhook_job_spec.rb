require "rails_helper"

RSpec.describe OnboardingWebhookJob, type: :job do
  let(:profile) do
    users(:candidate).create_candidate_profile!(
      first_name: "Jane", last_name: "Doe", email: "jane@example.com",
      city: "Amsterdam", desired_job_function: "general_dentist",
      years_of_experience: 5, status: "completed", completed_at: Time.current
    )
  end

  around do |example|
    config = Rails.application.config.onboarding
    original = config.webhook_url
    config.webhook_url = "https://hooks.example.test/candidates"
    example.run
    config.webhook_url = original
  end

  def http_response(klass, code, message)
    klass.new("1.1", code, message)
  end

  it "posts the candidate summary as JSON and succeeds on a 2xx" do
    captured = nil
    allow_any_instance_of(Net::HTTP).to receive(:request) do |_http, request|
      captured = request
      http_response(Net::HTTPOK, "200", "OK")
    end

    expect { described_class.perform_now(profile.id) }.not_to raise_error

    expect(captured["Content-Type"]).to eq("application/json")
    body = JSON.parse(captured.body)
    expect(body["event"]).to eq("candidate_onboarding_completed")
    expect(body.dig("candidate", "email")).to eq("jane@example.com")
    expect(body.dig("candidate", "job_function")).to eq("general_dentist")
  end

  it "retries (does not silently drop) when the endpoint returns a non-2xx" do
    allow_any_instance_of(Net::HTTP).to receive(:request)
      .and_return(http_response(Net::HTTPInternalServerError, "500", "Server Error"))

    expect { described_class.perform_now(profile.id) }
      .to have_enqueued_job(described_class)
  end

  it "does nothing when the profile no longer exists" do
    expect_any_instance_of(Net::HTTP).not_to receive(:request)
    described_class.perform_now(0)
  end

  it "does nothing when the webhook is not configured" do
    Rails.application.config.onboarding.webhook_url = ""
    expect_any_instance_of(Net::HTTP).not_to receive(:request)
    described_class.perform_now(profile.id)
  end
end

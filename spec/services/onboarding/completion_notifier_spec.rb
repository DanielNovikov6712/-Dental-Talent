require "rails_helper"

RSpec.describe Onboarding::CompletionNotifier do
  let(:profile) { users(:candidate).create_candidate_profile!(email: "jane@example.com") }

  it "emails the recruitment team" do
    expect { described_class.call(profile) }
      .to have_enqueued_mail(AdminMailer, :candidate_onboarding_completed).with(profile)
  end

  it "does not trigger the webhook when it is not configured" do
    expect { described_class.call(profile) }.not_to have_enqueued_job(OnboardingWebhookJob)
  end
end

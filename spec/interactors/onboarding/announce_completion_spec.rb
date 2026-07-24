require "rails_helper"

RSpec.describe Onboarding::AnnounceCompletion do
  let(:profile) { users(:candidate).create_candidate_profile!(email: "jane@example.com") }

  it "emails the recruitment team on the first completion" do
    expect { described_class.call(profile: profile, newly_completed: true) }
      .to have_enqueued_mail(AdminMailer, :candidate_onboarding_completed).with(profile)
  end

  it "does nothing when the completion is not new (a later edit)" do
    expect { described_class.call(profile: profile, newly_completed: false) }
      .not_to have_enqueued_mail(AdminMailer, :candidate_onboarding_completed)
  end

  it "does not trigger the webhook when it is not configured" do
    expect { described_class.call(profile: profile, newly_completed: true) }
      .not_to have_enqueued_job(OnboardingWebhookJob)
  end

  it "triggers the webhook when one is configured" do
    Rails.application.config.onboarding.webhook_url = "https://hooks.example.test/candidates"
    expect { described_class.call(profile: profile, newly_completed: true) }
      .to have_enqueued_job(OnboardingWebhookJob).with(profile.id)
  ensure
    Rails.application.config.onboarding.webhook_url = ""
  end
end

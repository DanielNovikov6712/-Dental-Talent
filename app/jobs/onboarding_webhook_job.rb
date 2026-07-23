require "net/http"

# Posts a "candidate_onboarding_completed" event to the configured webhook URL
# (PRD §10). Optional: only runs when ONBOARDING_WEBHOOK_URL is set. The payload
# deliberately contains only matching-relevant summary data — never the raw CV
# or parser output.
class OnboardingWebhookJob < ApplicationJob
  queue_as :default

  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError

  EVENT_NAME = "candidate_onboarding_completed".freeze

  def perform(profile_id)
    profile = CandidateProfile.find_by(id: profile_id)
    return unless profile && Onboarding.webhook_enabled?

    uri = URI.parse(Onboarding.webhook_url)
    response = Net::HTTP.post(uri, payload(profile).to_json, "Content-Type" => "application/json")

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("Onboarding webhook returned #{response.code} for profile #{profile_id}")
    end
  end

  private

  def payload(profile)
    {
      event: EVENT_NAME,
      occurred_at: profile.completed_at&.iso8601,
      candidate: {
        id: profile.id,
        name: profile.full_name,
        email: profile.email,
        city: profile.city,
        job_function: profile.desired_job_function,
        years_of_experience: profile.years_of_experience,
        skills: profile.candidate_skills.map(&:display_name)
      }
    }
  end
end

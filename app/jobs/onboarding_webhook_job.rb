require "net/http"

class OnboardingWebhookJob < ApplicationJob
  queue_as :default

  class DeliveryError < StandardError; end
  retry_on Net::OpenTimeout, Net::ReadTimeout, DeliveryError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  def perform(profile_id)
    profile = CandidateProfile.find_by(id: profile_id)
    return unless profile && Onboarding.webhook_enabled?

    response = post(URI.parse(Onboarding.webhook_url), payload(profile).to_json)
    return if response.is_a?(Net::HTTPSuccess)

    raise DeliveryError, "Onboarding webhook returned #{response.code} for profile #{profile_id}"
  end

  private

  def post(uri, body)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = Constants::OPEN_TIMEOUT
    http.read_timeout = Constants::READ_TIMEOUT

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = body

    http.request(request)
  end

  def payload(profile)
    {
      event: Constants::EVENT_NAME,
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

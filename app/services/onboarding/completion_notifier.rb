module Onboarding
  # Fired after a candidate completes onboarding (PRD §10): notifies the
  # recruitment team and, if configured, triggers the outbound webhook.
  class CompletionNotifier
    def self.call(profile)
      new(profile).call
    end

    def initialize(profile)
      @profile = profile
    end

    def call
      notify_recruitment_team
      trigger_webhook
    end

    private

    def notify_recruitment_team
      return unless Onboarding.recruitment_team_email

      AdminMailer.candidate_onboarding_completed(@profile).deliver_later
    end

    def trigger_webhook
      return unless Onboarding.webhook_enabled?

      OnboardingWebhookJob.perform_later(@profile.id)
    end
  end
end

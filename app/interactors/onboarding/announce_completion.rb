module Onboarding
  class AnnounceCompletion
    include Interactor

    def call
      return unless context.newly_completed

      profile = context.profile
      AdminMailer.candidate_onboarding_completed(profile).deliver_later if Onboarding.recruitment_team_email
      OnboardingWebhookJob.perform_later(profile.id) if Onboarding.webhook_enabled?
    end
  end
end

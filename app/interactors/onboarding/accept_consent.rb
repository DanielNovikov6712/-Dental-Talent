module Onboarding
  class AcceptConsent
    include Interactor

    def call
      profile = context.profile
      given = context.consent == "1" || profile.consent_accepted?
      context.fail!(error: I18n.t("onboarding.uploads.consent_required")) unless given

      profile.update!(consent_accepted: true) unless profile.consent_accepted?
    end
  end
end

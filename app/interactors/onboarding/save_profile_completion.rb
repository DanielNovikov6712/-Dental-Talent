module Onboarding
  class SaveProfileCompletion
    include Interactor

    def call
      profile = context.profile
      context.newly_completed = !profile.completed?

      profile.assign_attributes(context.attributes)
      profile.status = "completed"
      profile.completed_at ||= Time.current

      CandidateProfile.transaction do
        profile.save!(context: :complete)
        profile.replace_skill_selection(skill_ids: context.skill_ids, suggestions: context.suggestions)
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      profile.status = "draft" if context.newly_completed
      context.fail!
    end
  end
end

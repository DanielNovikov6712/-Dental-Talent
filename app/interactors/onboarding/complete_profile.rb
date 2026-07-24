module Onboarding
  class CompleteProfile
    include Interactor::Organizer

    organize SaveProfileCompletion, AnnounceCompletion
  end
end

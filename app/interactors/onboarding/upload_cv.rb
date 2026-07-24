module Onboarding
  class UploadCv
    include Interactor::Organizer

    organize ValidateUpload, AcceptConsent, StartCvParsing
  end
end

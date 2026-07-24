module Onboarding
  class StartCvParsing
    include Interactor

    def call
      file = context.file
      document = context.profile.candidate_documents.create!(
        document_type: "cv",
        original_filename: file.original_filename,
        content_type: file.content_type,
        file_size: file.size,
        parsing_status: "pending"
      )
      document.file.attach(file)

      ParseCandidateCvJob.perform_later(document)
      context.document = document
    end
  end
end

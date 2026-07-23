module Onboarding
  # Validates an uploaded CV against the configurable size limit and the allowed
  # file types (PDF/DOC/DOCX). Returns a human-readable error message, or nil
  # when the file is acceptable.
  class UploadValidator
    def self.error_for(file)
      new(file).error
    end

    def initialize(file)
      @file = file
    end

    def error
      return "Please choose a CV file to upload." if @file.blank?
      return "This file is too large. The maximum size is #{Onboarding.max_cv_size_mb} MB." if too_large?
      return "Unsupported file type. Please upload a PDF, DOC, or DOCX file." unless allowed_type?

      nil
    end

    private

    def too_large?
      @file.size.to_i > Onboarding.max_cv_size_bytes
    end

    # Accept on either signal: some browsers send a generic/empty content type,
    # so a matching extension is enough (and vice versa).
    def allowed_type?
      extension = File.extname(@file.original_filename.to_s).downcase
      Onboarding::ALLOWED_EXTENSIONS.include?(extension) ||
        Onboarding.allowed_content_types.include?(@file.content_type)
    end
  end
end

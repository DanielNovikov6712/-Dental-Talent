module Onboarding
  class ValidateUpload
    include Interactor

    def call
      file = context.file
      context.fail!(error: I18n.t("onboarding.uploads.missing_file")) if file.blank?
      context.fail!(error: too_large_message) if too_large?(file)
      context.fail!(error: I18n.t("onboarding.uploads.unsupported")) unless allowed_type?(file)
    end

    private

    def too_large?(file)
      file.size.to_i > Onboarding.max_cv_size_bytes
    end

    def too_large_message
      I18n.t("onboarding.uploads.too_large", max: Onboarding.max_cv_size_mb)
    end

    def allowed_type?(file)
      extension = File.extname(file.original_filename.to_s).downcase
      Constants::ALLOWED_EXTENSIONS.include?(extension) ||
        Onboarding.allowed_content_types.include?(file.content_type)
    end
  end
end

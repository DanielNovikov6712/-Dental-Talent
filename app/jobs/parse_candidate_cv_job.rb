class ParseCandidateCvJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(document)
    result = Cv::ParseCandidateCv.call(document: document)
    document.mark_failed!(result.error) if result.failure?
  rescue => error
    Rails.logger.error("CV parsing failed for document #{document.id}: #{error.class}: #{error.message}")
    document.mark_failed!(I18n.t("onboarding.parsing.failed"))
  end
end

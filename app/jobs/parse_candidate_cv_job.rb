# Parses an uploaded CV in the background and prefills the candidate profile.
# Runs the extract -> parse -> map pipeline and always leaves the document in a
# terminal state (completed/failed) so the upload screen can stop polling.
class ParseCandidateCvJob < ApplicationJob
  queue_as :default

  # If the document was deleted before the job ran, there is nothing to do.
  discard_on ActiveJob::DeserializationError

  def perform(document)
    document.mark_processing!

    text = Cv::TextExtractor.call(document)
    if text.blank?
      document.mark_failed!("We couldn't read any text from this file. Please continue manually.")
      return
    end

    result = Cv::Parser.call(text)
    Cv::ProfileMapper.new(document.candidate_profile, result).apply!
    document.mark_completed!(result.to_h)
  rescue Cv::UnsupportedFileError => error
    document.mark_failed!(error.message)
  rescue => error
    Rails.logger.error("CV parsing failed for document #{document.id}: #{error.class}: #{error.message}")
    document.mark_failed!("Something went wrong while reading this CV. Please continue manually.")
  end
end

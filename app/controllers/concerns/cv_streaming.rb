# Streams a CandidateDocument's attached file through the app so access is
# always authorized. CV files are never exposed via public Active Storage URLs
# (PRD §9: only the candidate and authorized staff may view the CV).
module CvStreaming
  extend ActiveSupport::Concern

  private

  def send_cv(document)
    unless document&.file&.attached?
      return redirect_back fallback_location: root_path, alert: "No CV is available for download."
    end

    send_data document.file.download,
      filename: document.original_filename.presence || document.file.filename.to_s,
      type: document.content_type.presence || document.file.content_type,
      disposition: "attachment"
  end
end

module CvStreaming
  extend ActiveSupport::Concern

  included do
    include ActiveStorage::Streaming
  end

  private

  def send_cv(document)
    unless document&.file&.attached?
      return redirect_back fallback_location: root_path, alert: t("onboarding.documents.missing_cv")
    end

    send_blob_stream document.file, disposition: "attachment"
  end
end

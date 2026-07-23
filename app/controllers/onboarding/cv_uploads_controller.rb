module Onboarding
  # Step 1 — CV upload. Handles the upload itself, the "continue manually"
  # escape hatch, and consent capture. Parsing happens in the background
  # (ParseCandidateCvJob); this controller only kicks it off.
  class CvUploadsController < BaseController
    def show
      return redirect_to onboarding_profile_path if @candidate_profile.completed?

      if (document = active_document)
        return redirect_to onboarding_document_path(document)
      end

      @document = @candidate_profile.candidate_documents.new
    end

    def create
      return render_upload_error("Please choose a CV file to upload.") if uploaded_file.blank?
      return render_upload_error("Please accept the consent statement to continue.") unless consent_given?

      if (message = UploadValidator.error_for(uploaded_file))
        return render_upload_error(message)
      end

      record_consent
      @document = build_document(uploaded_file)
      @document.save!
      ParseCandidateCvJob.perform_later(@document)

      redirect_to onboarding_document_path(@document)
    end

    # "Continue manually" — skip parsing and go straight to the review form.
    def continue_manually
      return render_upload_error("Please accept the consent statement to continue.") unless consent_given?

      record_consent
      redirect_to edit_onboarding_profile_path
    end

    private

    def uploaded_file
      params[:file]
    end

    def consent_given?
      params[:consent] == "1" || @candidate_profile.consent_accepted?
    end

    # Most recent CV that is still being parsed (so we don't start over on reload).
    def active_document
      @candidate_profile.candidate_documents
        .where(parsing_status: %w[pending processing]).recent.first
    end

    def record_consent
      return if @candidate_profile.consent_accepted?

      @candidate_profile.update!(consent_accepted: true)
    end

    def build_document(file)
      document = @candidate_profile.candidate_documents.new(
        document_type: "cv",
        original_filename: file.original_filename,
        content_type: file.content_type,
        file_size: file.size,
        parsing_status: "pending"
      )
      document.file.attach(file)
      document
    end

    def render_upload_error(message)
      @document = @candidate_profile.candidate_documents.new
      flash.now[:alert] = message
      render :show, status: :unprocessable_content
    end
  end
end

module Onboarding
  class CvUploadsController < BaseController
    def show
      return redirect_to onboarding_profile_path if @candidate_profile.completed?

      if (document = active_document)
        return redirect_to onboarding_document_path(document)
      end

      @document = @candidate_profile.candidate_documents.new
    end

    def create
      result = UploadCv.call(profile: @candidate_profile, file: params[:file], consent: params[:consent])

      if result.success?
        redirect_to onboarding_document_path(result.document)
      else
        render_upload_error(result.error)
      end
    end

    def continue_manually
      result = AcceptConsent.call(profile: @candidate_profile, consent: params[:consent])

      if result.success?
        redirect_to edit_onboarding_profile_path
      else
        render_upload_error(result.error)
      end
    end

    private

    def active_document
      @candidate_profile.candidate_documents
        .where(parsing_status: %w[pending processing]).recent.first
    end

    def render_upload_error(message)
      @document = @candidate_profile.candidate_documents.new
      flash.now[:alert] = message
      render :show, status: :unprocessable_content
    end
  end
end

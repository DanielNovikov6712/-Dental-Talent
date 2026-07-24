module Onboarding
  class DocumentsController < BaseController
    include CvStreaming

    before_action :set_document

    def show
      redirect_to edit_onboarding_profile_path if @document.parsing_finished?
    end

    def status
      render json: {
        status: @document.parsing_status,
        finished: @document.parsing_finished?,
        redirect_url: edit_onboarding_profile_path
      }
    end

    def download
      send_cv(@document)
    end

    private

    def set_document
      @document = @candidate_profile.candidate_documents.find(params[:id])
    end
  end
end

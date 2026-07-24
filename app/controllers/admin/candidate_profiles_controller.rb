module Admin
  class CandidateProfilesController < BaseController
    include CvStreaming

    before_action :set_profile, only: %i[show cv]

    def index
      scope = CandidateProfile.completed.recent
      @total_pages = [ (scope.count.to_f / Constants::PER_PAGE).ceil, 1 ].max
      @page = params[:page].to_i.clamp(1, @total_pages)
      @profiles = scope.limit(Constants::PER_PAGE).offset((@page - 1) * Constants::PER_PAGE)
    end

    def show
    end

    def cv
      send_cv(@profile.candidate_documents.cvs.recent.first)
    end

    private

    def set_profile
      @profile = CandidateProfile.completed
        .includes(:educations, :work_experiences, :candidate_skills, :candidate_languages)
        .find(params[:id])
    end
  end
end

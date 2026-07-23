module Admin
  # Recruiter / admin view of completed candidate profiles (PRD §12: "Admin /
  # recruitment team can view the completed profile").
  class CandidateProfilesController < BaseController
    include CvStreaming

    before_action :set_profile, only: %i[show cv]

    def index
      @profiles = CandidateProfile.completed.recent
    end

    def show
    end

    def cv
      send_cv(@profile.candidate_documents.cvs.recent.first)
    end

    private

    # Only completed profiles are shared with the recruitment team (PRD §12);
    # a draft id therefore 404s rather than exposing unsubmitted data.
    def set_profile
      @profile = CandidateProfile.completed
        .includes(:educations, :work_experiences, :candidate_skills, :candidate_languages)
        .find(params[:id])
    end
  end
end

module ProfileReviewForm
  extend ActiveSupport::Concern

  private

  def prepare_form
    ensure_one_blank_row
    set_skill_form_state
    warn_if_cv_parsing_failed
  end

  def ensure_one_blank_row
    @candidate_profile.educations.build if @candidate_profile.educations.empty?
    @candidate_profile.work_experiences.build if @candidate_profile.work_experiences.empty?
    @candidate_profile.candidate_languages.build if @candidate_profile.candidate_languages.empty?
  end

  def set_skill_form_state
    @selected_skill_ids = Array(params[:skill_ids] || @candidate_profile.skill_ids).map(&:to_i)
    @suggested_skills = params[:suggested_skills] ||
      @candidate_profile.candidate_skills.suggestions.map(&:name).join(", ")
  end

  def warn_if_cv_parsing_failed
    return unless current_cv_document&.failed?

    flash.now[:alert] = t("onboarding.profiles.cv_unreadable")
  end

  def current_cv_document
    @current_cv_document ||= @candidate_profile.candidate_documents.cvs.recent.first
  end
end

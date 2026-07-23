module Onboarding
  # Step 2 — Review & complete the profile. `edit` renders the prefilled,
  # sectioned form; `update` runs the full completion validations and, on the
  # first draft -> completed transition, notifies the recruitment team.
  class ProfilesController < BaseController
    helper_method :current_cv_document

    def show
      redirect_to edit_onboarding_profile_path unless @candidate_profile.completed?
    end

    def edit
      prepare_form
    end

    def update
      was_completed = @candidate_profile.completed?

      @candidate_profile.assign_attributes(profile_params)
      @candidate_profile.status = "completed"
      @candidate_profile.completed_at ||= Time.current

      if save_completed_profile
        # Only notify on the first completion, not on later edits (PRD §10).
        CompletionNotifier.call(@candidate_profile) unless was_completed
        redirect_to onboarding_profile_path, notice: "Your profile has been saved. Thank you!"
      else
        @candidate_profile.status = "draft" unless was_completed
        prepare_form
        flash.now[:alert] = "Please correct the highlighted fields before saving."
        render :edit, status: :unprocessable_content
      end
    end

    private

    def save_completed_profile
      CandidateProfile.transaction do
        @candidate_profile.save!(context: :complete)
        @candidate_profile.replace_skill_selection(
          skill_ids: params[:skill_ids],
          suggestions: params[:suggested_skills]
        )
      end
      true
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      false
    end

    def prepare_form
      ensure_one_blank_row
      set_skill_form_state
      warn_if_cv_parsing_failed
    end

    # Show at least one empty row for each repeater so the form is usable.
    def ensure_one_blank_row
      @candidate_profile.educations.build if @candidate_profile.educations.empty?
      @candidate_profile.work_experiences.build if @candidate_profile.work_experiences.empty?
      @candidate_profile.candidate_languages.build if @candidate_profile.candidate_languages.empty?
    end

    # Seed the skills UI from the submitted params on re-render (so a validation
    # error elsewhere doesn't silently discard the candidate's skill choices),
    # falling back to the persisted selection on a fresh GET.
    def set_skill_form_state
      @selected_skill_ids = Array(params[:skill_ids] || @candidate_profile.skill_ids).map(&:to_i)
      @suggested_skills = params[:suggested_skills] ||
        @candidate_profile.candidate_skills.suggestions.map(&:name).join(", ")
    end

    def warn_if_cv_parsing_failed
      return unless current_cv_document&.failed?

      flash.now[:alert] = "We couldn't read your CV automatically — please fill in your details below."
    end

    def current_cv_document
      @current_cv_document ||= @candidate_profile.candidate_documents.cvs.recent.first
    end

    def profile_params
      params.require(:candidate_profile).permit(
        :first_name, :last_name, :email, :phone_number, :city, :country,
        :desired_job_function, :max_travel_time, :search_status, :reason_for_looking,
        :desired_gross_salary, :desired_percentage, :average_daily_revenue,
        :big_registration_status, :big_number, :years_of_experience,
        :available_from, :notice_period,
        :motivation, :internal_notes, :professional_summary,
        :consent_accepted,
        preferred_regions: [], transport_types: [], employment_types: [], available_working_days: [],
        educations_attributes: %i[id institution study location level start_date end_date position _destroy],
        work_experiences_attributes: %i[id job_title company_name responsibilities start_date end_date current position _destroy],
        candidate_languages_attributes: %i[id language_id name level _destroy]
      )
    end
  end
end

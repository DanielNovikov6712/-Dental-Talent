module Onboarding
  class ProfilesController < BaseController
    include ProfileReviewForm

    helper_method :current_cv_document

    def show
      redirect_to edit_onboarding_profile_path unless @candidate_profile.completed?
    end

    def edit
      prepare_form
    end

    def update
      result = CompleteProfile.call(
        profile: @candidate_profile,
        attributes: profile_params,
        skill_ids: params[:skill_ids],
        suggestions: params[:suggested_skills]
      )

      if result.success?
        redirect_to onboarding_profile_path, notice: t("onboarding.profiles.saved")
      else
        prepare_form
        flash.now[:alert] = t("onboarding.profiles.invalid")
        render :edit, status: :unprocessable_content
      end
    end

    private

    def profile_params
      params.require(:candidate_profile).permit(
        :first_name, :last_name, :email, :phone_number, :city, :country,
        :desired_job_function, :max_travel_time, :search_status, :reason_for_looking,
        :desired_gross_salary, :desired_percentage, :average_daily_revenue,
        :big_registration_status, :big_number, :years_of_experience,
        :available_from, :notice_period,
        :motivation, :professional_summary,
        :consent_accepted,
        preferred_regions: [], transport_types: [], employment_types: [], available_working_days: [],
        educations_attributes: %i[id institution study location level start_date end_date position _destroy],
        work_experiences_attributes: %i[id job_title company_name responsibilities start_date end_date current position _destroy],
        candidate_languages_attributes: %i[id language_id name level _destroy]
      )
    end
  end
end

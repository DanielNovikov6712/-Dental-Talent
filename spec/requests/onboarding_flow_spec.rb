require "rails_helper"

RSpec.describe "Onboarding flow", type: :request do
  let(:candidate) { users(:candidate) }

  def valid_profile_params
    {
      first_name: "Jane", last_name: "Doe", email: "jane@example.com",
      phone_number: "+31 6 12345678", city: "Amsterdam", country: "Netherlands",
      desired_job_function: "general_dentist", search_status: "active",
      max_travel_time: 30, years_of_experience: 5,
      preferred_regions: [ "utrecht" ], employment_types: [ "employed" ],
      transport_types: [ "car" ], available_working_days: %w[monday tuesday],
      available_from: Date.current.to_s, consent_accepted: "1",
      candidate_languages_attributes: { "0" => { language_id: languages(:dutch).id, level: "native" } }
    }
  end

  it "requires authentication" do
    get onboarding_cv_upload_path
    expect(response).to redirect_to(new_session_path)
  end

  context "when signed in as a candidate" do
    before { sign_in_as(candidate) }

    it "lands on the upload screen" do
      get onboarding_cv_upload_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Upload your CV")
    end

    it "requires consent to continue manually" do
      post onboarding_continue_manually_path
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "records consent and opens the review form when continuing manually" do
      post onboarding_continue_manually_path, params: { consent: "1" }
      expect(response).to redirect_to(edit_onboarding_profile_path)
      expect(candidate.reload.candidate_profile).to be_consent_accepted
    end

    it "renders all review sections" do
      candidate.candidate_profile!
      get edit_onboarding_profile_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Personal details", "Job preferences", "Education", "Work experience", "Skills")
    end

    it "saves and completes a fully filled profile" do
      profile = candidate.candidate_profile!

      patch onboarding_profile_path, params: {
        candidate_profile: valid_profile_params,
        skill_ids: [ skills(:endodontics).id ],
        suggested_skills: "Communication, Teamwork"
      }

      expect(response).to redirect_to(onboarding_profile_path)
      profile.reload
      expect(profile).to be_completed
      expect(profile.first_name).to eq("Jane")
      expect(profile.skill_ids).to eq([ skills(:endodontics).id ])
      expect(profile.candidate_skills.suggestions.count).to eq(2)
      expect(profile.candidate_languages.count).to eq(1)
    end

    it "shows the completed summary after completion" do
      candidate.candidate_profile!
      patch onboarding_profile_path, params: { candidate_profile: valid_profile_params }
      get onboarding_profile_path
      expect(response).to have_http_status(:success)
      expect(response.body).to match(/complete/i)
    end

    it "rejects an incomplete submission with errors" do
      candidate.candidate_profile!
      patch onboarding_profile_path, params: { candidate_profile: { first_name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(candidate.candidate_profile.reload).not_to be_completed
    end

    it "shows a validation error (not a 500) when the same language is added twice" do
      candidate.candidate_profile!
      duplicated = valid_profile_params.merge(
        candidate_languages_attributes: {
          "0" => { language_id: languages(:dutch).id, level: "native" },
          "1" => { language_id: languages(:dutch).id, level: "fluent" }
        }
      )
      patch onboarding_profile_path, params: { candidate_profile: duplicated }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not re-notify or reset the completion date when editing a completed profile" do
      profile = candidate.candidate_profile!
      patch onboarding_profile_path, params: { candidate_profile: valid_profile_params }
      completed_at = profile.reload.completed_at

      # Re-submit without re-adding the language (the real form carries existing
      # ids); just change a scalar field.
      edit_params = valid_profile_params.except(:candidate_languages_attributes).merge(city: "Rotterdam")
      expect {
        patch onboarding_profile_path, params: { candidate_profile: edit_params }
      }.not_to have_enqueued_mail(AdminMailer, :candidate_onboarding_completed)

      expect(profile.reload.completed_at).to eq(completed_at)
      expect(profile.city).to eq("Rotterdam")
    end
  end
end

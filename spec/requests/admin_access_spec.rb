require "rails_helper"

RSpec.describe "Admin access", type: :request do
  def completed_profile(with_cv: false)
    profile = users(:candidate).create_candidate_profile!(
      first_name: "Jane", last_name: "Doe", email: "jane@example.com",
      phone_number: "+31 6 12345678", city: "Amsterdam",
      desired_job_function: "general_dentist", search_status: "active",
      max_travel_time: 30, years_of_experience: 5,
      preferred_regions: [ "utrecht" ], employment_types: [ "employed" ],
      available_working_days: [ "monday" ], available_from: Date.current,
      consent_accepted: true, status: "completed", completed_at: Time.current
    )
    profile.candidate_languages.create!(language: languages(:dutch), level: "native")

    if with_cv
      document = profile.candidate_documents.create!(
        document_type: "cv", original_filename: "cv.pdf", parsing_status: "completed"
      )
      document.file.attach(io: StringIO.new("dummy"), filename: "cv.pdf", content_type: "application/pdf")
    end

    profile
  end

  it "does not let candidates into the admin area" do
    sign_in_as users(:candidate)
    get admin_candidate_profiles_path
    expect(response).to redirect_to(root_path)
  end

  it "lets recruiters see completed profiles" do
    profile = completed_profile
    sign_in_as users(:recruiter)

    get admin_candidate_profiles_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include(profile.full_name)
  end

  it "lets recruiters view a profile and download its CV" do
    profile = completed_profile(with_cv: true)
    sign_in_as users(:recruiter)

    get admin_candidate_profile_path(profile)
    expect(response).to have_http_status(:success)

    get cv_admin_candidate_profile_path(profile)
    expect(response).to have_http_status(:success)
    expect(response.media_type).to eq("application/pdf")
  end

  it "does not expose draft (unsubmitted) profiles to staff" do
    draft = users(:candidate).create_candidate_profile!
    sign_in_as users(:recruiter)

    get admin_candidate_profile_path(draft)
    expect(response).to have_http_status(:not_found)
  end

  it "routes staff to the admin area from the landing page" do
    sign_in_as users(:admin)
    get root_path
    expect(response).to redirect_to(admin_candidate_profiles_path)
  end
end

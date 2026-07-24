require "rails_helper"

RSpec.describe "CV upload", type: :request do
  let(:candidate) { users(:candidate) }

  before { sign_in_as(candidate) }

  def pdf_upload
    fixture_file_upload("sample_cv.pdf", "application/pdf")
  end

  it "stores the document, records consent and enqueues parsing" do
    expect { post onboarding_cv_upload_path, params: { consent: "1", file: pdf_upload } }
      .to have_enqueued_job(ParseCandidateCvJob)

    profile = candidate.reload.candidate_profile
    expect(profile).to be_consent_accepted
    document = profile.candidate_documents.last
    expect(document.original_filename).to eq("sample_cv.pdf")
    expect(document.file).to be_attached
    expect(response).to redirect_to(onboarding_document_path(document))
  end

  it "rejects an upload without consent" do
    post onboarding_cv_upload_path, params: { file: pdf_upload }
    expect(response).to have_http_status(:unprocessable_content)
    expect(candidate.reload.candidate_profile&.candidate_documents).to be_blank
  end

  it "rejects an unsupported file type" do
    post onboarding_cv_upload_path, params: {
      consent: "1", file: fixture_file_upload("notes.txt", "text/plain")
    }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "reports parsing status as JSON" do
    post onboarding_cv_upload_path, params: { consent: "1", file: pdf_upload }
    document = candidate.reload.candidate_profile.candidate_documents.last

    get status_onboarding_document_path(document)
    expect(response).to have_http_status(:success)
    expect(response.parsed_body).to include("status" => "pending", "finished" => false)
  end

  it "lets a candidate download their own CV" do
    post onboarding_cv_upload_path, params: { consent: "1", file: pdf_upload }
    document = candidate.reload.candidate_profile.candidate_documents.last

    get download_onboarding_document_path(document)
    expect(response).to have_http_status(:success)
    expect(response.media_type).to eq("application/pdf")
  end

  it "moves on from the processing page once parsing has finished" do
    profile = candidate.candidate_profile!
    document = profile.candidate_documents.create!(
      document_type: "cv", original_filename: "cv.pdf", parsing_status: "completed", parsed_at: Time.current
    )
    get onboarding_document_path(document)
    expect(response).to redirect_to(edit_onboarding_profile_path)
  end

  it "warns on the review form when CV parsing failed" do
    profile = candidate.candidate_profile!
    profile.candidate_documents.create!(
      document_type: "cv", original_filename: "cv.pdf", parsing_status: "failed", parsing_error: "unreadable"
    )
    get edit_onboarding_profile_path
    expect(response.body).to match(/read your CV automatically/i)
  end

  it "reports a finished status with a redirect url once parsing completes" do
    profile = candidate.candidate_profile!
    document = profile.candidate_documents.create!(
      document_type: "cv", original_filename: "cv.pdf", parsing_status: "completed", parsed_at: Time.current
    )
    get status_onboarding_document_path(document)
    expect(response.parsed_body).to include(
      "status" => "completed", "finished" => true, "redirect_url" => edit_onboarding_profile_path
    )
  end

  it "does not let a candidate reach another candidate's CV or status" do
    other = User.create!(email_address: "other@example.com", password: "password123", role: "candidate")
    other_document = other.candidate_profile!.candidate_documents.create!(
      document_type: "cv", original_filename: "cv.pdf", parsing_status: "completed", parsed_at: Time.current
    )

    get download_onboarding_document_path(other_document)
    expect(response).to have_http_status(:not_found)

    get status_onboarding_document_path(other_document)
    expect(response).to have_http_status(:not_found)
  end
end

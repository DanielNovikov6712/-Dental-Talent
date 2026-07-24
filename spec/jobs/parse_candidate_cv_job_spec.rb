require "rails_helper"

RSpec.describe ParseCandidateCvJob, type: :job do
  let(:profile) { users(:candidate).create_candidate_profile! }

  def build_document(filename, io, content_type)
    document = profile.candidate_documents.create!(
      document_type: "cv", original_filename: filename, parsing_status: "pending"
    )
    document.file.attach(io: io, filename: filename, content_type: content_type)
    document
  end

  it "extracts text, prefills the profile and completes the document" do
    document = build_document("cv.doc", file_fixture("sample_cv.doc").open, "application/msword")

    described_class.perform_now(document)

    expect(document.reload).to be_completed
    expect(document.parsed_at).to be_present
    expect(profile.reload.email).to eq("jane@example.com")
    expect(profile.desired_job_function).to eq("general_dentist")
    expect(profile.extracted?(:email)).to be(true)
  end

  it "marks the document failed when no text can be extracted" do
    document = build_document("cv.doc", StringIO.new("hi"), "application/msword")

    described_class.perform_now(document)

    expect(document.reload).to be_failed
    expect(document.parsing_error).to be_present
  end

  it "marks the document failed for an unsupported file type" do
    document = build_document("cv.rtf", StringIO.new("plenty of readable text here"), "application/rtf")

    described_class.perform_now(document)

    expect(document.reload).to be_failed
  end

  it "parses a real PDF end to end" do
    document = build_document("cv.pdf", file_fixture("sample_cv.pdf").open, "application/pdf")

    described_class.perform_now(document)

    expect(document.reload).to be_completed
    expect(profile.reload.email).to eq("jane@example.com")
    expect(profile.desired_job_function).to eq("general_dentist")
  end

  it "marks the document failed with a generic message when mapping raises" do
    document = build_document("cv.pdf", file_fixture("sample_cv.pdf").open, "application/pdf")
    allow(Cv::MapProfile).to receive(:call!).and_raise(StandardError, "boom")

    described_class.perform_now(document)

    expect(document.reload).to be_failed
    expect(document.parsing_error).to match(/something went wrong/i)
  end
end

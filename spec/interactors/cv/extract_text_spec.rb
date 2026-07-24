require "rails_helper"

RSpec.describe Cv::ExtractText do
  let(:profile) { users(:candidate).create_candidate_profile! }

  def document_for(filename, content_type)
    document = profile.candidate_documents.create!(
      document_type: "cv", original_filename: filename, parsing_status: "pending"
    )
    document.file.attach(io: file_fixture(filename).open, filename: filename, content_type: content_type)
    document
  end

  it "extracts text from a real PDF" do
    result = described_class.call(document: document_for("sample_cv.pdf", "application/pdf"))
    expect(result).to be_success
    expect(result.text).to include("jane@example.com", "Tandarts")
  end

  it "extracts text from a real DOCX" do
    result = described_class.call(
      document: document_for("sample_cv.docx",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    )
    expect(result).to be_success
    expect(result.text).to include("jane@example.com", "Amsterdam")
  end

  it "scrapes readable text from a best-effort .doc" do
    result = described_class.call(document: document_for("sample_cv.doc", "application/msword"))
    expect(result.text).to include("jane@example.com")
  end

  it "fails for an unsupported file type" do
    result = described_class.call(document: document_for("notes.txt", "text/plain"))
    expect(result).to be_failure
    expect(result.error).to be_present
  end

  it "fails (never raises) when the file is not attached" do
    document = profile.candidate_documents.create!(
      document_type: "cv", original_filename: "cv.pdf", parsing_status: "pending"
    )
    expect(described_class.call(document: document)).to be_failure
  end
end

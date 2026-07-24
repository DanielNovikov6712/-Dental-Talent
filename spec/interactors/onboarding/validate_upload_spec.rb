require "rails_helper"

RSpec.describe Onboarding::ValidateUpload do
  def upload(name, type)
    Rack::Test::UploadedFile.new(file_fixture(name), type)
  end

  it "accepts a PDF within the size limit" do
    expect(described_class.call(file: upload("sample_cv.pdf", "application/pdf"))).to be_success
  end

  it "fails without a file" do
    result = described_class.call(file: nil)
    expect(result).to be_failure
    expect(result.error).to match(/choose a CV/i)
  end

  it "fails for unsupported file types" do
    result = described_class.call(file: upload("notes.txt", "text/plain"))
    expect(result).to be_failure
    expect(result.error).to match(/unsupported/i)
  end

  it "fails for files over the configured limit" do
    original = Rails.application.config.onboarding.max_cv_size_mb
    Rails.application.config.onboarding.max_cv_size_mb = 0
    result = described_class.call(file: upload("sample_cv.pdf", "application/pdf"))
    expect(result).to be_failure
    expect(result.error).to match(/too large/i)
  ensure
    Rails.application.config.onboarding.max_cv_size_mb = original
  end
end

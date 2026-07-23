require "rails_helper"

RSpec.describe Onboarding::UploadValidator do
  def upload(name, type)
    Rack::Test::UploadedFile.new(file_fixture(name), type)
  end

  it "accepts a PDF within the size limit" do
    expect(described_class.error_for(upload("sample_cv.pdf", "application/pdf"))).to be_nil
  end

  it "requires a file" do
    expect(described_class.error_for(nil)).to match(/choose a CV/i)
  end

  it "rejects unsupported file types" do
    expect(described_class.error_for(upload("notes.txt", "text/plain"))).to match(/unsupported/i)
  end

  it "rejects files over the configured limit" do
    original = Rails.application.config.onboarding.max_cv_size_mb
    Rails.application.config.onboarding.max_cv_size_mb = 0
    expect(described_class.error_for(upload("sample_cv.pdf", "application/pdf"))).to match(/too large/i)
  ensure
    Rails.application.config.onboarding.max_cv_size_mb = original
  end
end

require "rails_helper"

RSpec.describe AdminMailer, type: :mailer do
  describe "candidate_onboarding_completed" do
    let(:profile) do
      users(:candidate).create_candidate_profile!(
        first_name: "Jane", last_name: "Doe", email: "jane@example.com",
        city: "Amsterdam", desired_job_function: "general_dentist", years_of_experience: 5
      )
    end

    subject(:mail) { described_class.candidate_onboarding_completed(profile) }

    it "is addressed to the recruitment team with a descriptive subject" do
      expect(mail.to).to eq([ Onboarding.recruitment_team_email ])
      expect(mail.subject).to include("Jane Doe")
    end

    it "renders the candidate summary" do
      expect(mail.body.encoded).to include("General dentist")
      expect(mail.body.encoded).to include("jane@example.com")
    end
  end
end

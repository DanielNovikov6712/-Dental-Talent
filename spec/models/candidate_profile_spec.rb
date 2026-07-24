require "rails_helper"

RSpec.describe CandidateProfile, type: :model do
  let(:profile) { users(:candidate).create_candidate_profile! }

  def assign_complete_attributes(overrides = {})
    profile.assign_attributes({
      first_name: "Jane", last_name: "Doe", email: "jane@example.com",
      phone_number: "+31 6 12345678", city: "Amsterdam",
      desired_job_function: "general_dentist", search_status: "active",
      max_travel_time: 30, years_of_experience: 5,
      preferred_regions: [ "utrecht" ], employment_types: [ "employed" ],
      available_working_days: [ "monday" ], available_from: Date.current,
      consent_accepted: true
    }.merge(overrides))
  end

  describe "draft vs completion validation" do
    it "is valid as a blank draft" do
      expect(profile).to be_valid
    end

    it "does not enforce completion requirements on a draft" do
      expect(profile).to be_valid
      expect(profile.valid?(:complete)).to be(false)
      expect(profile.errors).to be_of_kind(:first_name, :blank)
    end

    it "requires core fields, consent and a language to complete" do
      assign_complete_attributes(consent_accepted: false)
      expect(profile.valid?(:complete)).to be(false)
      expect(profile.errors.added?(:consent_accepted, "must be given before saving your profile")).to be(true)
    end

    it "is valid for completion when fully filled" do
      assign_complete_attributes
      profile.candidate_languages.build(language: languages(:dutch), level: "native")
      expect(profile.valid?(:complete)).to be(true), profile.errors.full_messages.to_sentence
    end
  end

  describe "multi-select array attributes" do
    it "rejects blanks and de-duplicates" do
      profile.preferred_regions = [ "", "utrecht", "utrecht" ]
      profile.valid?
      expect(profile.preferred_regions).to eq([ "utrecht" ])
    end

    it "rejects values outside the allowed set" do
      profile.transport_types = [ "spaceship" ]
      expect(profile).not_to be_valid
      expect(profile.errors).to be_of_kind(:transport_types, :inclusion)
    end
  end

  describe "gross salary" do
    it "rejects fractional input instead of silently truncating it" do
      profile.desired_gross_salary = "3500.75"
      expect(profile).not_to be_valid
      expect(profile.errors).to be_of_kind(:desired_gross_salary, :not_an_integer)
    end
  end

  describe "phone number" do
    it "accepts international formats" do
      profile.phone_number = "+31 (0)6 1234 5678"
      expect(profile).to be_valid
    end

    it "rejects implausible values" do
      profile.phone_number = "12"
      expect(profile).not_to be_valid
      expect(profile.errors).to be_of_kind(:phone_number, :invalid)
    end
  end

  describe "BIG number" do
    it "is required only when BIG registered" do
      assign_complete_attributes
      profile.candidate_languages.build(language: languages(:dutch), level: "native")
      profile.big_registration_status = "big_registered"
      profile.big_number = ""
      expect(profile.valid?(:complete)).to be(false)
      expect(profile.errors).to be_of_kind(:big_number, :blank)

      profile.big_number = "12345678901"
      expect(profile.valid?(:complete)).to be(true)
    end
  end

  describe "conditional-logic helpers" do
    it "follow the selected function" do
      profile.desired_job_function = "general_dentist"
      expect(profile.requires_big?).to be(true)
      expect(profile.revenue_relevant?).to be(true)
      expect(profile.skill_group).to eq("dentist")

      profile.desired_job_function = "front_office"
      expect(profile.requires_big?).to be(false)
      expect(profile.skill_group).to eq("front_office")
    end

    it "follow the selected employment types" do
      profile.employment_types = [ "employed" ]
      expect(profile.salary_relevant?).to be(true)
      expect(profile.percentage_relevant?).to be(false)

      profile.employment_types = [ "self_employed" ]
      expect(profile.percentage_relevant?).to be(true)
    end
  end

  describe "#replace_skill_selection" do
    it "keeps only skills from the active group plus free-text suggestions" do
      profile.update!(desired_job_function: "general_dentist")
      profile.replace_skill_selection(
        skill_ids: [ skills(:endodontics).id, skills(:periodontology).id ],
        suggestions: "Leadership, Leadership, Empathy"
      )

      expect(profile.candidate_skills.matched.pluck(:skill_id)).to eq([ skills(:endodontics).id ])
      expect(profile.candidate_skills.suggestions.pluck(:name)).to match_array(%w[Leadership Empathy])
    end
  end

  describe "conditional field reconciliation on completion" do
    it "clears fields the chosen function/employment make irrelevant" do
      profile.assign_attributes(
        status: "completed",
        desired_job_function: "dental_assistant", employment_types: [ "self_employed" ],
        desired_gross_salary: 4000, average_daily_revenue: 800,
        big_registration_status: "big_registered", big_number: "123"
      )
      profile.valid?

      expect(profile.desired_gross_salary).to be_nil
      expect(profile.average_daily_revenue).to be_nil
      expect(profile.big_registration_status).to be_nil
      expect(profile.big_number).to be_nil
    end

    it "keeps fields the chosen function/employment make relevant" do
      profile.assign_attributes(
        status: "completed",
        desired_job_function: "general_dentist", employment_types: [ "employed" ],
        desired_gross_salary: 4000, average_daily_revenue: 800, big_number: "12345678901"
      )
      profile.valid?

      expect(profile.desired_gross_salary).to eq(4000)
      expect(profile.average_daily_revenue).to eq(800)
      expect(profile.big_number).to eq("12345678901")
    end

    it "does not clear extracted values on a lenient draft" do
      profile.assign_attributes(desired_job_function: nil, big_number: "12345678901")
      profile.valid?
      expect(profile.big_number).to eq("12345678901")
    end
  end

  describe "duplicate languages" do
    it "is invalid when the same language is added twice" do
      profile.candidate_languages.build(language: languages(:dutch))
      profile.candidate_languages.build(language: languages(:dutch))

      expect(profile).not_to be_valid
      expect(profile.errors[:base]).to include("Each language can only be added once")
    end
  end

  describe "consent" do
    it "stamps the accepted-at timestamp once accepted" do
      expect(profile.consent_accepted_at).to be_nil
      profile.update!(consent_accepted: true)
      expect(profile.consent_accepted_at).to be_present
    end
  end
end

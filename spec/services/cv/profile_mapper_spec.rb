require "rails_helper"

RSpec.describe Cv::ProfileMapper do
  let(:profile) { users(:candidate).create_candidate_profile! }

  it "maps extracted fields onto the profile and records their source" do
    result = Cv::ParsedResult.new
    result.first_name = "Jane"
    result.email = "jane@example.com"
    result.desired_job_function = "general_dentist"

    described_class.new(profile, result).apply!
    profile.reload

    expect(profile.first_name).to eq("Jane")
    expect(profile.desired_job_function).to eq("general_dentist")
    expect(profile.extracted?(:first_name)).to be(true)
    expect(profile.extracted?(:desired_job_function)).to be(true)
    expect(profile.extracted?(:city)).to be(false)
  end

  it "builds nested education, work and language records" do
    result = Cv::ParsedResult.new
    result.educations << { study: "Tandheelkunde", institution: "UvA", level: "master" }
    result.work_experiences << { job_title: "Tandarts", company_name: "Kliniek", current: true }
    result.languages << { name: "Dutch", level: "native" }

    described_class.new(profile, result).apply!
    profile.reload

    expect(profile.educations.count).to eq(1)
    expect(profile.work_experiences.count).to eq(1)
    expect(profile.candidate_languages.first.language).to eq(languages(:dutch))
    expect(profile.candidate_languages.first).to be_from_cv
  end

  it "matches known skills and keeps unknown ones as suggestions" do
    profile.update!(desired_job_function: "general_dentist")
    result = Cv::ParsedResult.new
    result.skills.concat([ "Endodontics", "Some Niche Skill" ])

    described_class.new(profile, result).apply!
    profile.reload

    expect(profile.candidate_skills.matched.pluck(:skill_id)).to eq([ skills(:endodontics).id ])
    expect(profile.candidate_skills.suggestions.pluck(:name)).to eq([ "Some Niche Skill" ])
    expect(profile.candidate_skills.suggestions.first).to be_from_cv
  end

  it "leaves the profile as a valid draft" do
    result = Cv::ParsedResult.new
    result.first_name = "Jane"
    described_class.new(profile, result).apply!
    expect(profile.reload).to be_draft
  end

  it "is idempotent — re-applying does not duplicate CV-sourced records" do
    result = Cv::ParsedResult.new
    result.educations << { study: "Tandheelkunde", level: "master" }
    result.work_experiences << { job_title: "Tandarts", company_name: "Kliniek" }
    result.languages << { name: "Dutch", level: "native" }

    described_class.new(profile, result).apply!
    described_class.new(profile.reload, result).apply!
    profile.reload

    expect(profile.educations.count).to eq(1)
    expect(profile.work_experiences.count).to eq(1)
    expect(profile.candidate_languages.count).to eq(1)
  end

  it "does not clobber the candidate's own manually added records" do
    profile.educations.create!(study: "Manual entry", from_cv: false)
    result = Cv::ParsedResult.new
    result.educations << { study: "Tandheelkunde", level: "master" }

    described_class.new(profile, result).apply!
    described_class.new(profile.reload, result).apply! # a second CV upload
    profile.reload

    expect(profile.educations.pluck(:study)).to contain_exactly("Manual entry", "Tandheelkunde")
  end
end

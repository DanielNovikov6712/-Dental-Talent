require "rails_helper"

RSpec.describe Cv::HeuristicParser do
  SAMPLE = <<~CV.freeze
    Jane Doe
    Tandarts

    Email: jane.doe@example.com
    Telefoon: +31 6 12345678
    Woonplaats: Amsterdam, Nederland

    Profiel
    Ervaren tandarts met 8 jaar ervaring.

    BIG-nummer: 12345678901

    Werkervaring
    Tandarts
    Tandartspraktijk Centrum B.V.
    2018 - heden

    Opleiding
    Tandheelkunde
    Universiteit van Amsterdam
    Master
    2009 - 2015

    Vaardigheden
    Endodontics, Surgery, Communicatie

    Talen
    Nederlands: moedertaal
    Engels: vloeiend
  CV

  subject(:result) { described_class.call(SAMPLE) }

  it "extracts contact details" do
    expect(result).to have_attributes(
      first_name: "Jane",
      last_name: "Doe",
      email: "jane.doe@example.com",
      phone_number: "+31 6 12345678",
      city: "Amsterdam",
      country: "Netherlands"
    )
  end

  it "detects job function, experience and BIG registration" do
    expect(result).to have_attributes(
      desired_job_function: "general_dentist",
      years_of_experience: 8,
      big_number: "12345678901",
      big_registration_status: "big_registered"
    )
  end

  it "extracts languages with levels" do
    expect(result.languages).to eq(
      [ { name: "Dutch", level: "native" }, { name: "English", level: "fluent" } ]
    )
  end

  it "extracts a non-Dutch country" do
    text = "Jane Doe\nEmail: jane@example.com\nWoonplaats: Antwerpen, België\n"
    expect(described_class.call(text).country).to eq("Belgium")
  end

  it "infers the BIG status from the text rather than always 'big_registered'" do
    text = "Tandarts\nBIG-registratie: in aanvraag\n"
    result = described_class.call(text)
    expect(result.big_registration_status).to eq("in_progress")
    expect(result.big_number).to be_nil
  end

  it "extracts education and work experience records" do
    expect(result.educations.size).to eq(1)
    expect(result.educations.first).to include(study: "Tandheelkunde", level: "master")

    expect(result.work_experiences.size).to eq(1)
    expect(result.work_experiences.first).to include(job_title: "Tandarts", current: true)
  end

  it "extracts skills as a list" do
    expect(result.skills).to include("Endodontics", "Surgery")
  end

  it "does not invent data for an empty or unhelpful CV" do
    empty = described_class.call("...\n\n---")
    expect(empty.first_name).to be_nil
    expect(empty.email).to be_nil
    expect(empty.desired_job_function).to be_nil
    expect(empty.languages).to be_empty
    expect(empty.educations).to be_empty
  end

  it "does not raise on nil, empty or binary input" do
    expect { described_class.call(nil) }.not_to raise_error
    expect { described_class.call("") }.not_to raise_error
    expect { described_class.call("\x00\xFF binary \x10 garbage".b) }.not_to raise_error
  end

  describe "confident extraction (never guesses)" do
    it "does not infer a job function from an incidental word in prose" do
      text = "Profiel\nI am a communication specialist who loves working with people.\n"
      expect(described_class.call(text).desired_job_function).to be_nil
    end

    it "does not treat a job-title header line as the candidate's name" do
      text = "Dental Hygienist\nAmsterdam\nEmail: x@example.com\n"
      expect(described_class.call(text).first_name).to be_nil
    end

    it "ignores prose written under a Skills heading" do
      text = "Vaardigheden\nI am good at many things and enjoy helping patients every single day.\n"
      expect(described_class.call(text).skills).to be_empty
    end
  end
end

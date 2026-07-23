require "rails_helper"

RSpec.describe User, type: :model do
  it "downcases and strips the email address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    expect(user.email_address).to eq("downcased@example.com")
  end

  it "requires a valid, unique email address" do
    user = User.new(email_address: "not-an-email", password: "password123")
    expect(user).not_to be_valid
    expect(user.errors[:email_address]).to be_present

    duplicate = User.new(email_address: users(:candidate).email_address, password: "password123")
    expect(duplicate).not_to be_valid
  end

  it "enforces a minimum password length" do
    user = User.new(email_address: "new@example.com", password: "short")
    expect(user).not_to be_valid
    expect(user.errors[:password]).to be_present
  end

  it "only allows known roles" do
    expect(User.new(email_address: "r@example.com", password: "password123", role: "wizard")).not_to be_valid
  end

  describe "role predicates" do
    it "distinguishes candidates from staff" do
      expect(users(:candidate)).to be_candidate
      expect(users(:candidate)).not_to be_staff
      expect(users(:recruiter)).to be_staff
      expect(users(:admin)).to be_staff
    end
  end

  describe "#candidate_profile!" do
    it "lazily creates the profile seeded with the user's email" do
      user = users(:candidate)
      expect(user.candidate_profile).to be_nil
      profile = user.candidate_profile!
      expect(profile).to be_persisted
      expect(profile.email).to eq(user.email_address)
      expect(user.candidate_profile!).to eq(profile)
    end
  end
end

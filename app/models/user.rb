class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :candidate_profile, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :role, inclusion: { in: Constants::ROLES }

  def candidate? = role == "candidate"
  def recruiter? = role == "recruiter"
  def admin?     = role == "admin"

  def staff? = recruiter? || admin?

  def candidate_profile!
    candidate_profile || create_candidate_profile!(email: email_address)
  end
end

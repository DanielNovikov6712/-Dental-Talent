class User < ApplicationRecord
  ROLES = %w[candidate recruiter admin].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :candidate_profile, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :role, inclusion: { in: ROLES }

  def candidate? = role == "candidate"
  def recruiter? = role == "recruiter"
  def admin?     = role == "admin"

  # Recruiters and admins may view candidate profiles and CVs.
  def staff? = recruiter? || admin?

  # Every candidate has exactly one profile; create it lazily so the onboarding
  # flow always has a profile to work with.
  def candidate_profile!
    candidate_profile || create_candidate_profile!(email: email_address)
  end
end

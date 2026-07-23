class CandidateSkill < ApplicationRecord
  belongs_to :candidate_profile
  # Optional: unknown skills detected in a CV are kept as free-text suggestions
  # (no matching Skill) for recruiter review.
  belongs_to :skill, optional: true

  before_validation :copy_name_from_skill

  validates :name, presence: true, if: -> { skill_id.blank? }
  validates :skill_id, uniqueness: { scope: :candidate_profile_id }, allow_nil: true

  scope :matched,    -> { where.not(skill_id: nil) }
  scope :suggestions, -> { where(skill_id: nil) }

  # Prefer the denormalized name (copied from the skill on save) so rendering a
  # list of skills doesn't lazily load each Skill association.
  def display_name
    name.presence || skill&.name
  end

  private

  def copy_name_from_skill
    self.name = skill.name if skill.present?
  end
end

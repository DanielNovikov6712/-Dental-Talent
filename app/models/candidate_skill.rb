class CandidateSkill < ApplicationRecord
  belongs_to :candidate_profile

  belongs_to :skill, optional: true

  before_validation :copy_name_from_skill

  validates :name, presence: true, if: -> { skill_id.blank? }
  validates :skill_id, uniqueness: { scope: :candidate_profile_id }, allow_nil: true

  validate :free_text_name_not_duplicated

  scope :matched,    -> { where.not(skill_id: nil) }
  scope :suggestions, -> { where(skill_id: nil) }

  def display_name
    name.presence || skill&.name
  end

  private

  def copy_name_from_skill
    self.name = skill.name if skill.present?
  end

  def free_text_name_not_duplicated
    return if skill_id.present? || name.blank? || candidate_profile.nil?

    duplicates = candidate_profile.candidate_skills.suggestions
      .where.not(id: id).where("LOWER(name) = ?", name.downcase)
    errors.add(:name, :taken) if duplicates.exists?
  end
end

class CandidateLanguage < ApplicationRecord
  belongs_to :candidate_profile
  belongs_to :language, optional: true

  before_validation :copy_name_from_language

  validates :name, presence: true, if: -> { language_id.blank? }
  validates :level,
    inclusion: { in: Constants::LANGUAGE_LEVELS.keys }, allow_blank: true
  validates :language_id, uniqueness: { scope: :candidate_profile_id }, allow_nil: true

  validate :free_text_name_not_duplicated

  def display_name
    name.presence || language&.name
  end

  def level_label
    Onboarding::Options.label(Constants::LANGUAGE_LEVELS, level) if level.present?
  end

  private

  def copy_name_from_language
    self.name = language.name if language.present?
  end

  def free_text_name_not_duplicated
    return if language_id.present? || name.blank? || candidate_profile.nil?

    duplicates = candidate_profile.candidate_languages.where(language_id: nil)
      .where.not(id: id).where("LOWER(name) = ?", name.downcase)
    errors.add(:name, :taken) if duplicates.exists?
  end
end

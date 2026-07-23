class CandidateLanguage < ApplicationRecord
  belongs_to :candidate_profile
  belongs_to :language, optional: true

  before_validation :copy_name_from_language

  validates :name, presence: true, if: -> { language_id.blank? }
  validates :level,
    inclusion: { in: Onboarding::Options::LANGUAGE_LEVELS.keys }, allow_blank: true
  validates :language_id, uniqueness: { scope: :candidate_profile_id }, allow_nil: true

  # Prefer the denormalized name (copied from the language on save) so rendering
  # a list of languages doesn't lazily load each Language association.
  def display_name
    name.presence || language&.name
  end

  def level_label
    Onboarding::Options.label(Onboarding::Options::LANGUAGE_LEVELS, level) if level.present?
  end

  private

  def copy_name_from_language
    self.name = language.name if language.present?
  end
end

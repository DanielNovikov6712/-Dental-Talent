class Skill < ApplicationRecord
  has_many :candidate_skills, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: { scope: :function_group, case_sensitive: false }
  validates :function_group,
    presence: true, inclusion: { in: Onboarding::Options::SKILL_GROUPS.keys }

  scope :ordered, -> { order(:function_group, :position, :name) }
  scope :for_group, ->(group) { where(function_group: group).order(:position, :name) }

  # Case-insensitive lookup used when matching skills detected in a CV to the
  # platform's fixed skill list.
  def self.match(name, group: nil)
    scope = group ? where(function_group: group) : all
    scope.where("LOWER(name) = ?", name.to_s.strip.downcase).first
  end

  # Split a free-text list ("Endodontics, aligners") into clean, de-duplicated
  # suggestion names.
  def self.normalize_suggestions(text)
    text.to_s.split(/[,;\n]/).map(&:strip).reject(&:blank?).uniq { |name| name.downcase }
  end
end

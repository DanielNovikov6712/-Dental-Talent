class Skill < ApplicationRecord
  has_many :candidate_skills, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: { scope: :function_group, case_sensitive: false }
  validates :function_group,
    presence: true, inclusion: { in: Constants::SKILL_GROUPS.keys }

  scope :ordered, -> { order(:function_group, :position, :name) }
  scope :for_group, ->(group) { where(function_group: group).order(:position, :name) }

  def self.match(name, group: nil)
    scope = group ? where(function_group: group) : all
    scope.where("LOWER(name) = ?", name.to_s.strip.downcase).first
  end

  def self.normalize_suggestions(text)
    text.to_s.split(/[,;\n]/).map(&:strip).reject(&:blank?).uniq { |name| name.downcase }
  end
end

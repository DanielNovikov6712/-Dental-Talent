class Language < ApplicationRecord
  has_many :candidate_languages, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :ordered, -> { order(:position, :name) }

  def self.match(name)
    where("LOWER(name) = ?", name.to_s.strip.downcase).first
  end
end

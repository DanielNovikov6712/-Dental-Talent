class Education < ApplicationRecord
  include DateRangeValidatable

  belongs_to :candidate_profile

  validates :study, presence: true, on: :complete
  validates :level,
    inclusion: { in: Constants::EDUCATION_LEVELS.keys }, allow_blank: true
end

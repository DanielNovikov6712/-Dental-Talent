class WorkExperience < ApplicationRecord
  include DateRangeValidatable

  belongs_to :candidate_profile

  before_validation :clear_end_date_when_current

  validates :job_title, :company_name, presence: true, on: :complete

  private

  def clear_end_date_when_current
    self.end_date = nil if current?
  end
end

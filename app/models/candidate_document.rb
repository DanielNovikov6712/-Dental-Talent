class CandidateDocument < ApplicationRecord
  belongs_to :candidate_profile
  has_one_attached :file

  enum :parsing_status,
    { pending: "pending", processing: "processing", completed: "completed", failed: "failed" },
    default: "pending"

  validates :document_type, inclusion: { in: Constants::DOCUMENT_TYPES }

  scope :cvs, -> { where(document_type: "cv") }
  scope :recent, -> { order(created_at: :desc) }

  def parsing_finished?
    completed? || failed?
  end

  def mark_processing!
    update!(parsing_status: :processing, parsing_error: nil)
  end

  def mark_completed!(parsed_data)
    update!(parsing_status: :completed, parsed_at: Time.current, parsed_data: parsed_data, parsing_error: nil)
  end

  def mark_failed!(error)
    update!(parsing_status: :failed, parsed_at: Time.current, parsing_error: error.to_s.truncate(250))
  end
end

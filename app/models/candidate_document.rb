class CandidateDocument < ApplicationRecord
  DOCUMENT_TYPES  = %w[cv].freeze
  PARSING_STATUSES = %w[pending processing completed failed].freeze

  belongs_to :candidate_profile
  has_one_attached :file

  validates :document_type, inclusion: { in: DOCUMENT_TYPES }
  validates :parsing_status, inclusion: { in: PARSING_STATUSES }

  scope :cvs, -> { where(document_type: "cv") }
  scope :recent, -> { order(created_at: :desc) }

  PARSING_STATUSES.each do |state|
    define_method("#{state}?") { parsing_status == state }
  end

  # Terminal states — the candidate can move on to the review step.
  def parsing_finished?
    completed? || failed?
  end

  def mark_processing!
    update!(parsing_status: "processing", parsing_error: nil)
  end

  def mark_completed!(parsed_data)
    update!(parsing_status: "completed", parsed_at: Time.current, parsed_data: parsed_data, parsing_error: nil)
  end

  def mark_failed!(error)
    update!(parsing_status: "failed", parsed_at: Time.current, parsing_error: error.to_s.truncate(250))
  end
end

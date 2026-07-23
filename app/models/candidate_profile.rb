class CandidateProfile < ApplicationRecord
  STATUSES = %w[draft completed].freeze

  # Multi-select columns stored as JSON arrays.
  ARRAY_ATTRIBUTES = %i[
    preferred_regions transport_types employment_types
    available_working_days extracted_fields
  ].freeze

  PHONE_FORMAT = /\A\+?[\d\s().\-\/]+\z/

  belongs_to :user

  has_many :candidate_documents, dependent: :destroy
  has_many :educations, -> { order(:position, :id) },
    dependent: :destroy, inverse_of: :candidate_profile
  has_many :work_experiences, -> { order(:position, :id) },
    dependent: :destroy, inverse_of: :candidate_profile
  has_many :candidate_skills, dependent: :destroy, inverse_of: :candidate_profile
  has_many :skills, through: :candidate_skills
  has_many :candidate_languages, dependent: :destroy, inverse_of: :candidate_profile
  has_many :languages, through: :candidate_languages

  accepts_nested_attributes_for :educations, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :work_experiences, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :candidate_languages, allow_destroy: true,
    reject_if: ->(attrs) { attrs[:language_id].blank? && attrs[:name].blank? }

  before_validation :normalize_array_attributes
  before_validation :reset_irrelevant_conditional_fields
  before_save :stamp_consent_accepted_at

  # --- Always-on validations (safe for partially filled drafts) ---------------
  validates :status, inclusion: { in: STATUSES }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :desired_job_function,
    inclusion: { in: Onboarding::Options::JOB_FUNCTIONS.keys }, allow_blank: true
  validates :search_status,
    inclusion: { in: Onboarding::Options::SEARCH_STATUSES.keys }, allow_blank: true
  validates :big_registration_status,
    inclusion: { in: Onboarding::Options::BIG_REGISTRATION_STATUSES.keys }, allow_blank: true
  validates :preferred_regions, array_inclusion: { in: Onboarding::Options::REGIONS.keys }
  validates :transport_types, array_inclusion: { in: Onboarding::Options::TRANSPORT_TYPES.keys }
  validates :employment_types, array_inclusion: { in: Onboarding::Options::EMPLOYMENT_TYPES.keys }
  validates :available_working_days, array_inclusion: { in: Onboarding::Options::WORKING_DAYS.keys }
  validates :max_travel_time,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :years_of_experience,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :desired_gross_salary,
    numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :desired_percentage,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :average_daily_revenue,
    numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :phone_number_plausible
  validate :candidate_languages_distinct

  # --- Completion-only validations (run when the candidate submits) -----------
  with_options on: :complete do |profile|
    profile.validates :first_name, :last_name, :phone_number, :city, :email, presence: true
    profile.validates :desired_job_function, :search_status, presence: true
    profile.validates :max_travel_time, :years_of_experience, presence: true
    profile.validates :preferred_regions, :employment_types, :available_working_days, presence: true
    profile.validates :available_from, presence: true
    profile.validate :at_least_one_language
    profile.validate :big_number_present_when_registered
    profile.validate :consent_must_be_accepted
  end

  scope :completed, -> { where(status: "completed") }
  scope :recent, -> { order(completed_at: :desc, updated_at: :desc) }

  def draft?     = status == "draft"
  def completed? = status == "completed"

  def full_name
    [ first_name, last_name ].compact_blank.join(" ")
  end

  # --- Conditional-form logic (shared by the view and completion validations) -
  def skill_group          = Onboarding::Options.skill_group_for(desired_job_function)
  def requires_big?        = Onboarding::Options.requires_big_registration?(desired_job_function)
  def revenue_relevant?    = Onboarding::Options.revenue_relevant?(desired_job_function)
  def salary_relevant?     = Onboarding::Options.salary_relevant?(employment_types)
  def percentage_relevant? = Onboarding::Options.percentage_relevant?(employment_types)

  # Attributes prefilled from a CV, used to render "Extracted from CV" badges.
  def extracted?(attribute)
    Array(extracted_fields).include?(attribute.to_s)
  end

  def mark_extracted(*attributes)
    self.extracted_fields = (Array(extracted_fields) + attributes.map(&:to_s)).uniq
  end

  # Replace the candidate's skill selection with the given matched skill ids
  # (restricted to the active function group) plus free-text suggestions.
  def replace_skill_selection(skill_ids:, suggestions:)
    group = skill_group
    allowed = group ? Skill.for_group(group) : Skill.none
    chosen  = Array(skill_ids).map(&:to_s)

    transaction do
      candidate_skills.destroy_all
      allowed.where(id: chosen).find_each { |skill| candidate_skills.create!(skill: skill) }
      Skill.normalize_suggestions(suggestions).each do |name|
        candidate_skills.create!(name: name, suggested: true)
      end
    end
  end

  # Used by the parser to prefill skills detected in a CV: match to the platform
  # list where possible, otherwise keep as a free-text suggestion for recruiters.
  def prefill_cv_skills(names)
    group = skill_group
    Array(names).map { |n| n.to_s.strip }.reject(&:blank?).uniq { |n| n.downcase }.each do |name|
      skill = group && Skill.match(name, group: group)
      if skill
        candidate_skills.find_or_initialize_by(skill: skill).tap { |cs| cs.from_cv = true }.save!
      elsif candidate_skills.none? { |cs| cs.skill_id.nil? && cs.name.to_s.casecmp?(name) }
        candidate_skills.create!(name: name, suggested: true, from_cv: true)
      end
    end
  end

  private

  def stamp_consent_accepted_at
    self.consent_accepted_at ||= Time.current if consent_accepted?
  end

  def normalize_array_attributes
    ARRAY_ATTRIBUTES.each do |attribute|
      value = self[attribute]
      next unless value.is_a?(Array)

      self[attribute] = value.map { |element| element.to_s.strip }.reject(&:blank?).uniq
    end
  end

  # Clear conditional fields that the current function / employment type make
  # irrelevant, so a value entered before switching (client-side fields are only
  # hidden, not removed) can never be persisted on the final profile. Mirrors how
  # skills are filtered to the active function group. Only applied when the
  # profile is being completed, so lenient drafts (e.g. mid-CV-prefill) keep any
  # value that was extracted before the function was known.
  def reset_irrelevant_conditional_fields
    return unless status == "completed"

    self.desired_gross_salary = nil unless salary_relevant?
    self.desired_percentage = nil unless percentage_relevant?
    self.average_daily_revenue = nil unless revenue_relevant?

    unless requires_big?
      self.big_registration_status = nil
      self.big_number = nil
    end
  end

  def candidate_languages_distinct
    language_ids = candidate_languages.reject(&:marked_for_destruction?).filter_map(&:language_id)
    return if language_ids.uniq.length == language_ids.length

    errors.add(:base, "Each language can only be added once")
  end

  def phone_number_plausible
    return if phone_number.blank?

    digits = phone_number.scan(/\d/).size
    unless phone_number.match?(PHONE_FORMAT) && digits.between?(7, 15)
      errors.add(:phone_number, :invalid)
    end
  end

  def at_least_one_language
    return if candidate_languages.reject(&:marked_for_destruction?).any?

    errors.add(:base, "Select at least one language")
  end

  def big_number_present_when_registered
    return unless big_registration_status == Onboarding::Options::BIG_REGISTERED_STATUS
    return if big_number.present?

    errors.add(:big_number, :blank)
  end

  def consent_must_be_accepted
    return if consent_accepted?

    errors.add(:consent_accepted, "must be given before saving your profile")
  end
end

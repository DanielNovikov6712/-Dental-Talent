module Cv
  class ParsedResult
    SCALAR_FIELDS = %i[
      first_name last_name email phone_number city country
      desired_job_function years_of_experience big_number big_registration_status
      professional_summary
    ].freeze

    attr_accessor(*SCALAR_FIELDS)
    attr_reader :languages, :educations, :work_experiences, :skills

    def initialize
      @languages        = []
      @educations       = []
      @work_experiences = []
      @skills           = []
    end

    def present_scalar_fields
      SCALAR_FIELDS.select { |field| public_send(field).present? }
    end

    def to_h
      SCALAR_FIELDS.index_with { |field| public_send(field) }.merge(
        languages: languages,
        educations: educations,
        work_experiences: work_experiences,
        skills: skills
      )
    end
  end
end

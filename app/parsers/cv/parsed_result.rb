module Cv
  class ParsedResult
    attr_accessor(*Constants::SCALAR_FIELDS)
    attr_reader :languages, :educations, :work_experiences, :skills

    def initialize
      @languages        = []
      @educations       = []
      @work_experiences = []
      @skills           = []
    end

    def present_scalar_fields
      Constants::SCALAR_FIELDS.select { |field| public_send(field).present? }
    end

    def to_h
      Constants::SCALAR_FIELDS.index_with { |field| public_send(field) }.merge(
        languages: languages,
        educations: educations,
        work_experiences: work_experiences,
        skills: skills
      )
    end
  end
end

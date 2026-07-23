module Cv
  # Applies a Cv::ParsedResult to a (draft) CandidateProfile: sets only the
  # fields that were extracted, records which ones came from the CV (for the
  # "Extracted from CV" badges), and builds the nested education / work / language
  # / skill records. Everything runs in one transaction and is saved with the
  # default (draft) context so partial data never blocks the prefill.
  #
  # Idempotent: re-running (e.g. after a second CV upload) first clears the
  # previously CV-sourced records, so it never duplicates rows or collides with
  # the candidate's own manual entries.
  class ProfileMapper
    def initialize(profile, result)
      @profile = profile
      @result  = result
    end

    def apply!
      @profile.transaction do
        reset_cv_prefill
        assign_scalar_fields
        build_languages
        build_educations
        build_work_experiences
        @profile.save!
        assign_skills
      end
    end

    private

    def reset_cv_prefill
      @profile.educations.where(from_cv: true).destroy_all
      @profile.work_experiences.where(from_cv: true).destroy_all
      @profile.candidate_languages.where(from_cv: true).destroy_all
      @profile.candidate_skills.where(from_cv: true).destroy_all
      @profile.extracted_fields = []
    end

    def assign_scalar_fields
      fields = @result.present_scalar_fields
      fields.each { |field| @profile.public_send("#{field}=", @result.public_send(field)) }
      @profile.mark_extracted(*fields)
    end

    def build_languages
      return if @result.languages.empty?

      @result.languages.each do |attrs|
        language = Language.match(attrs[:name])
        next if language.nil? && attrs[:name].blank?
        next if language && @profile.candidate_languages.exists?(language_id: language.id)

        @profile.candidate_languages.build(
          language: language,
          name: (attrs[:name] unless language),
          level: valid_level(attrs[:level]),
          from_cv: true
        )
      end
      @profile.mark_extracted(:languages)
    end

    def build_educations
      return if @result.educations.empty?

      @result.educations.each_with_index do |attrs, index|
        @profile.educations.build(
          attrs.slice(:institution, :study, :location, :level, :start_date, :end_date)
            .merge(position: index, from_cv: true)
        )
      end
      @profile.mark_extracted(:educations)
    end

    def build_work_experiences
      return if @result.work_experiences.empty?

      @result.work_experiences.each_with_index do |attrs, index|
        @profile.work_experiences.build(
          attrs.slice(:job_title, :company_name, :responsibilities, :start_date, :end_date, :current)
            .merge(position: index, from_cv: true)
        )
      end
      @profile.mark_extracted(:work_experiences)
    end

    def assign_skills
      return if @result.skills.empty?

      @profile.prefill_cv_skills(@result.skills)
      return unless @profile.candidate_skills.exists?

      @profile.mark_extracted(:skills)
      @profile.save!
    end

    def valid_level(level)
      level if Onboarding::Options::LANGUAGE_LEVELS.key?(level.to_s)
    end
  end
end

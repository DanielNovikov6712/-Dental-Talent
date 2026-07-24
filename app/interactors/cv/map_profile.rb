module Cv
  class MapProfile
    include Interactor

    def call
      @profile = context.profile
      @result  = context.parsed_result

      return if @profile.completed?

      @profile.transaction do
        reset_cv_prefill
        assign_scalar_fields
        build_languages
        build_educations
        build_work_experiences
        build_skills
        @profile.save!
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

    def build_skills
      group = @profile.skill_group
      names = @result.skills.map { |name| name.to_s.strip }.reject(&:blank?).uniq { |name| name.downcase }
      added = false

      names.each do |name|
        if (skill = group && Skill.match(name, group: group))
          next if @profile.candidate_skills.any? { |cs| cs.skill_id == skill.id }

          @profile.candidate_skills.build(skill: skill, from_cv: true)
        elsif @profile.candidate_skills.none? { |cs| cs.skill_id.nil? && cs.name.to_s.casecmp?(name) }
          @profile.candidate_skills.build(name: name, suggested: true, from_cv: true)
        else
          next
        end
        added = true
      end

      @profile.mark_extracted(:skills) if added
    end

    def valid_level(level)
      level if Constants::LANGUAGE_LEVELS.key?(level.to_s)
    end
  end
end

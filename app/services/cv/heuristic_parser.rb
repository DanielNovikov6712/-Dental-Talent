module Cv
  # Rule-based CV parser (Dutch + English). Deterministic and dependency-free so
  # it is fully unit-testable and never calls an external service. It is a
  # strategy behind Cv::Parser.call — an LLM-backed strategy can replace it
  # without changing the extractor, mapper, or job.
  #
  # Guiding rule (PRD §5): only populate a field when it is confidently found;
  # never guess. Anything uncertain is left blank for the candidate to complete.
  class HeuristicParser
    EMAIL_REGEXP = /[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}/i
    PHONE_REGEXP = /(?<![\w])(\+?\d[\d\s().\-]{6,}\d)/
    YEAR_REGEXP  = /\b(?:19|20)\d{2}\b/
    PRESENT_REGEXP = /\b(?:present|current|now|heden)\b/i

    # Canonical section => heading matcher (matched against a normalised,
    # colon-stripped, downcased heading line).
    SECTION_PATTERNS = {
      summary:     /\A(professional\s+)?(summary|profile|profiel|persoonlijk profiel|over mij|about me)\z/,
      experience:  /\A(work\s+)?(experience|employment history|employment|werkervaring|ervaring|loopbaan)\z/,
      education:   /\A(education|opleiding(en)?|onderwijs|studies?)\z/,
      skills:      /\A(skills|competenties|vaardigheden|kwaliteiten)\z/,
      languages:   /\A(languages|talen|taalvaardigheid)\z/
    }.freeze

    # CV title => canonical English language name.
    LANGUAGE_NAMES = {
      "dutch" => "Dutch", "nederlands" => "Dutch",
      "english" => "English", "engels" => "English",
      "german" => "German", "duits" => "German",
      "french" => "French", "frans" => "French",
      "spanish" => "Spanish", "spaans" => "Spanish",
      "italian" => "Italian", "italiaans" => "Italian",
      "polish" => "Polish", "pools" => "Polish",
      "portuguese" => "Portuguese", "portugees" => "Portuguese",
      "turkish" => "Turkish", "turks" => "Turkish",
      "arabic" => "Arabic", "arabisch" => "Arabic",
      "ukrainian" => "Ukrainian", "oekraïens" => "Ukrainian",
      "russian" => "Russian", "russisch" => "Russian"
    }.freeze

    LEVEL_KEYWORDS = {
      "native" => "native", "moedertaal" => "native", "mother tongue" => "native",
      "fluent" => "fluent", "vloeiend" => "fluent",
      "c2" => "c2", "c1" => "c1", "b2" => "b2", "b1" => "b1", "a2" => "a2", "a1" => "a1",
      "basic" => "basic", "basis" => "basic", "beginner" => "basic"
    }.freeze

    # Ordered most-specific-first so "dental hygienist" wins over "dentist".
    JOB_FUNCTION_PATTERNS = [
      [ /mondhygi[eë]nist|dental hygienist|hygienist/i, "dental_hygienist" ],
      [ /paro[\-\s]?preventie/i,                        "paro_prevention_assistant" ],
      [ /preventie[\s\-]?assistent|prevention assistant/i, "prevention_assistant" ],
      [ /orthodont(ie|ic)[\s\-]?assistent|orthodontic assistant/i, "orthodontic_assistant" ],
      [ /tandartsassistent|dental assistant|dental nurse|tandarts[\s\-]?assistent/i, "dental_assistant" ],
      [ /praktijkmanager|practice manager|office manager/i, "practice_manager" ],
      [ /baliemedewerker|receptionist|front[\s\-]?office/i, "front_office" ],
      [ /tandtechnicus|dental technician|lab technician/i,  "dental_technician" ],
      [ /orthodontist|kaakchirurg|endodontoloog|parodontoloog|implantoloog|specialist/i, "specialist" ],
      [ /tandarts|dentist/i, "general_dentist" ]
    ].freeze

    INSTITUTION_KEYWORDS = /universiteit|hogeschool|university|college|institute|instituut|academy|academie|\broc\b|school/i
    COMPANY_KEYWORDS     = /\bb\.?v\.?\b|kliniek|praktijk|clinic|centre|center|tandarts|dental|ltd|gmbh|group/i

    def self.call(text)
      new(text).parse
    end

    def initialize(text)
      # Guard against nil / non-UTF-8 input so regex matching never raises.
      @text     = text.to_s.dup.force_encoding("UTF-8").scrub(" ")
      @lines    = @text.split("\n").map { |line| line.gsub(/[ \t]+/, " ").rstrip }
      @sections = split_sections
    end

    def parse
      result = ParsedResult.new

      assign_contact(result)
      assign_name(result)
      result.years_of_experience      = detect_years_of_experience
      assign_big_registration(result)
      result.professional_summary     = section_text(:summary).presence
      result.languages.concat(parse_languages)
      result.skills.concat(parse_skills)
      result.educations.concat(parse_educations)
      result.work_experiences.concat(parse_work_experiences)
      # Detect the function last, from a confident region (header title, an
      # explicit "Functie:" label, or the most recent job title) rather than the
      # whole document, so an incidental word can't invent a wrong function.
      result.desired_job_function = detect_job_function(function_focus(result))

      result
    end

    private

    # --- Whole-document extraction ---------------------------------------------

    def assign_contact(result)
      result.email        = @text[EMAIL_REGEXP]&.downcase
      result.phone_number = detect_phone
      city, country = detect_city_and_country
      result.city    = city
      result.country = country
    end

    def detect_phone
      candidate = labeled_value(/tel|phone|mobiel|mobile|gsm/i)
      match = candidate&.match(PHONE_REGEXP) || @text.match(PHONE_REGEXP)
      value = match && match[1].strip
      return nil unless value

      value if value.scan(/\d/).size.between?(7, 15)
    end

    def detect_city_and_country
      country = "Netherlands" if @text.match?(/\b(nederland|netherlands|the netherlands)\b/i)
      city = labeled_value(/woonplaats|city|plaats|residence|location/i)
      city = city&.split(/[,\d]/)&.first&.strip.presence
      [ city, country ]
    end

    # Text most likely to state the candidate's role: the header block, an
    # explicit function label, and their most recent job title.
    def function_focus(result)
      sources = section_lines(:header).dup
      sources << result.work_experiences.first&.dig(:job_title)
      sources << labeled_value(/functie|function|beroep|desired role|gewenste functie/i)
      sources.compact.join("\n")
    end

    def detect_job_function(focus)
      return if focus.blank?

      JOB_FUNCTION_PATTERNS.each do |regexp, function|
        return function if focus.match?(regexp)
      end
      nil
    end

    def detect_years_of_experience
      match = @text.match(/(\d{1,2})\s*\+?\s*(?:jaar|jr|years?|yrs?)\b[^.\n]{0,25}(?:ervaring|experience|werkervaring)/i)
      match ||= @text.match(/(?:ervaring|experience)[^0-9\n]{0,20}(\d{1,2})\s*(?:jaar|jr|years?)/i)
      match && match[1].to_i
    end

    def assign_big_registration(result)
      match = @text.match(/big[\s\-]*(?:nummer|number|registratie|registration|reg)?[\s:\-#]*([0-9]{6,15})/i)
      return unless match

      result.big_number = match[1]
      result.big_registration_status = Onboarding::Options::BIG_REGISTERED_STATUS
    end

    # --- Sections --------------------------------------------------------------

    # Splits the document into { canonical_section => [raw lines] }. Lines above
    # the first recognised heading go under :header.
    def split_sections
      sections = Hash.new { |hash, key| hash[key] = [] }
      current = :header

      @lines.each do |line|
        heading = heading_for(line)
        if heading
          current = heading
        else
          sections[current] << line
        end
      end

      sections
    end

    def heading_for(line)
      normalized = line.strip.downcase.chomp(":").strip
      return nil if normalized.empty? || normalized.length > 40

      SECTION_PATTERNS.each { |name, pattern| return name if normalized.match?(pattern) }
      nil
    end

    def section_lines(name)
      @sections.fetch(name, [])
    end

    def section_text(name)
      section_lines(name).map(&:strip).reject(&:blank?).join(" ").presence
    end

    # Groups a section's lines into blocks separated by blank lines.
    def section_blocks(name)
      section_lines(name).slice_when { |before, after| before.strip.empty? != after.strip.empty? }
        .map { |group| group.map(&:strip).reject(&:blank?) }
        .reject(&:empty?)
    end

    # --- Name ------------------------------------------------------------------

    def assign_name(result)
      name = labeled_value(/\b(name|naam)\b/i) || guess_name_from_header
      return if name.blank?

      parts = name.split(/\s+/)
      result.first_name = parts.first
      result.last_name  = parts[1..].join(" ").presence
    end

    def guess_name_from_header
      section_lines(:header).map(&:strip).reject(&:blank?).find do |line|
        next false if line.match?(/[@\d]/)
        next false if line.match?(/curriculum vitae|resume|\bcv\b/i)
        next false if line_is_job_or_org?(line) # e.g. a "Dental Hygienist" title line

        words = line.split(/\s+/)
        words.size.between?(2, 3) && words.all? { |word| word.match?(/\A[[:upper:]][[:alpha:]'\-]+\z/) }
      end
    end

    def line_is_job_or_org?(line)
      JOB_FUNCTION_PATTERNS.any? { |regexp, _| line.match?(regexp) } ||
        line.match?(INSTITUTION_KEYWORDS) || line.match?(COMPANY_KEYWORDS)
    end

    # --- Languages -------------------------------------------------------------

    def parse_languages
      lines = section_lines(:languages)
      return [] if lines.empty?

      lines.filter_map do |line|
        normalized = line.downcase
        name = LANGUAGE_NAMES.find { |title, _| normalized.include?(title) }&.last
        next unless name

        { name: name, level: detect_level(normalized) }
      end.uniq { |language| language[:name] }
    end

    def detect_level(text)
      LEVEL_KEYWORDS.each { |keyword, level| return level if text.include?(keyword) }
      nil
    end

    # --- Skills ----------------------------------------------------------------

    def parse_skills
      section_lines(:skills)
        .flat_map { |line| skill_tokens(line) }
        .map { |token| token.gsub(/\A[\s•·\-*]+/, "").strip }
        .reject { |token| token.blank? || token.length < 2 || token.length > 40 || token.split.size > 4 }
        .uniq { |token| token.downcase }
    end

    # Turn a skills-section line into tokens only when it looks like a list:
    # a delimited line splits on its delimiters; a short line is a single skill;
    # a long, undelimited line is prose and contributes nothing (never guess).
    def skill_tokens(line)
      if line.match?(/[,;•·|]/)
        line.split(/[,;•·|]/)
      elsif line.split.size <= 4
        [ line ]
      else
        []
      end
    end

    # --- Education -------------------------------------------------------------

    def parse_educations
      section_blocks(:education).filter_map do |block|
        years  = block.join(" ").scan(YEAR_REGEXP)
        study  = block.find { |line| !line.match?(/\A[\d\s\-–—to.]+\z/) }
        next unless study

        {
          study: study,
          institution: block.find { |line| line.match?(INSTITUTION_KEYWORDS) && line != study },
          level: detect_education_level(block.join(" ")),
          start_date: year_to_date(years.min),
          end_date: block_present?(block) ? nil : year_to_date(years.max)
        }.compact_blank
      end
    end

    def detect_education_level(text)
      Onboarding::Options::EDUCATION_LEVELS.keys.find do |level|
        text.match?(/\b#{Regexp.escape(level)}\b/i)
      end
    end

    # --- Work experience -------------------------------------------------------

    def parse_work_experiences
      section_blocks(:experience).filter_map do |block|
        content = block.reject { |line| line.match?(/\A[\d\s\-–—to.]+\z/) }
        next if content.empty?

        years = block.join(" ").scan(YEAR_REGEXP)
        {
          job_title: content[0],
          company_name: content.find { |line| line.match?(COMPANY_KEYWORDS) && line != content[0] } || content[1],
          responsibilities: content[2..]&.join("\n").presence,
          start_date: year_to_date(years.min),
          end_date: block_present?(block) ? nil : year_to_date(years.max),
          current: block_present?(block)
        }.compact_blank
      end
    end

    # --- Shared helpers --------------------------------------------------------

    def block_present?(block)
      block.any? { |line| line.match?(PRESENT_REGEXP) }
    end

    def year_to_date(year)
      return nil if year.blank?

      Date.new(year.to_i, 1, 1)
    rescue ArgumentError
      nil
    end

    # First captured value after a "Label: value" style line.
    def labeled_value(label_regexp)
      @lines.each do |line|
        if (match = line.match(/\A\s*#{label_regexp}\s*[:\-]\s*(.+)\z/))
          return match[1].strip.presence
        end
      end
      nil
    end
  end
end

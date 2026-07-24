module Constants
  ROLES = %w[candidate recruiter admin].freeze

  DOCUMENT_TYPES = %w[cv].freeze

  ALLOWED_EXTENSIONS = %w[.pdf .doc .docx].freeze
  SUPPORTED_EXTENSIONS = %w[.pdf .docx .doc].freeze
  DOC_SCAN_BYTES = 2.megabytes

  PER_PAGE = 25

  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 5
  EVENT_NAME = "candidate_onboarding_completed".freeze

  ARRAY_ATTRIBUTES = %i[
    preferred_regions transport_types employment_types
    available_working_days extracted_fields
  ].freeze

  WORK_EXPERIENCE_CORE_FIELDS = %i[
    job_title company_name responsibilities start_date end_date
  ].freeze

  PHONE_FORMAT = /\A\+?[\d\s().\-\/]+\z/

  SCALAR_FIELDS = %i[
    first_name last_name email phone_number city country
    desired_job_function years_of_experience big_number big_registration_status
    professional_summary
  ].freeze

  EMAIL_REGEXP = /[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}/i
  PHONE_REGEXP = /(?<![\w])(\+?\d[\d\s().\-]{6,}\d)/
  YEAR_REGEXP  = /\b(?:19|20)\d{2}\b/
  PRESENT_REGEXP = /\b(?:present|current|now|heden)\b/i

  SECTION_PATTERNS = {
    summary:     /\A(professional\s+)?(summary|profile|profiel|persoonlijk profiel|over mij|about me)\z/,
    experience:  /\A(work\s+)?(experience|employment history|employment|werkervaring|ervaring|loopbaan)\z/,
    education:   /\A(education|opleiding(en)?|onderwijs|studies?)\z/,
    skills:      /\A(skills|competenties|vaardigheden|kwaliteiten)\z/,
    languages:   /\A(languages|talen|taalvaardigheid)\z/
  }.freeze

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

  COUNTRY_NAMES = {
    "the netherlands" => "Netherlands", "netherlands" => "Netherlands", "nederland" => "Netherlands", "holland" => "Netherlands",
    "belgium" => "Belgium", "belgië" => "Belgium", "belgie" => "Belgium", "belgique" => "Belgium",
    "germany" => "Germany", "duitsland" => "Germany", "deutschland" => "Germany",
    "france" => "France", "frankrijk" => "France",
    "spain" => "Spain", "spanje" => "Spain", "españa" => "Spain",
    "italy" => "Italy", "italië" => "Italy", "italie" => "Italy",
    "poland" => "Poland", "polen" => "Poland",
    "portugal" => "Portugal",
    "united kingdom" => "United Kingdom", "england" => "United Kingdom",
    "ireland" => "Ireland", "ierland" => "Ireland",
    "austria" => "Austria", "oostenrijk" => "Austria",
    "switzerland" => "Switzerland", "zwitserland" => "Switzerland"
  }.freeze

  BIG_STATUS_KEYWORDS = [
    [ /\b(in\s*(aanvraag|behandeling|progress|process)|aangevraagd)\b/i, "in_progress" ],
    [ /\b(onder\s*supervisie|under\s*supervision)\b/i, "under_supervision" ],
    [ /\b(niet\s*van\s*toepassing|not\s*applicable|geen\s*big[\s\-]*registratie)\b/i, "not_applicable" ],
    [ /\bbig[\s\-]*(geregistreerd|registered)\b/i, "big_registered" ]
  ].freeze

  JOB_FUNCTIONS = {
    "general_dentist"          => "General dentist",
    "dental_hygienist"         => "Dental hygienist",
    "dental_assistant"         => "Dental assistant",
    "prevention_assistant"     => "Prevention assistant",
    "paro_prevention_assistant" => "Paro-prevention assistant",
    "orthodontic_assistant"    => "Orthodontic assistant",
    "front_office"             => "Front-office / receptionist",
    "practice_manager"         => "Practice manager",
    "dental_technician"        => "Dental technician",
    "specialist"               => "Specialist"
  }.freeze

  SKILL_GROUPS = {
    "dentist"           => "Dentist",
    "dental_hygienist"  => "Dental hygienist",
    "dental_assistant"  => "Dental assistant",
    "front_office"      => "Front-office",
    "practice_manager"  => "Practice manager",
    "dental_technician" => "Dental technician"
  }.freeze

  JOB_FUNCTION_TO_SKILL_GROUP = {
    "general_dentist"           => "dentist",
    "specialist"                => "dentist",
    "dental_hygienist"          => "dental_hygienist",
    "dental_assistant"          => "dental_assistant",
    "prevention_assistant"      => "dental_assistant",
    "paro_prevention_assistant" => "dental_assistant",
    "orthodontic_assistant"     => "dental_assistant",
    "front_office"              => "front_office",
    "practice_manager"          => "practice_manager",
    "dental_technician"         => "dental_technician"
  }.freeze

  BIG_REGISTRATION_FUNCTIONS = %w[general_dentist dental_hygienist specialist].freeze
  REVENUE_FUNCTIONS = %w[general_dentist dental_hygienist specialist prevention_assistant].freeze

  EMPLOYMENT_TYPES = {
    "employed"      => "Employed (loondienst)",
    "self_employed" => "Self-employed (ZZP)",
    "freelance"     => "Freelance",
    "temporary"     => "Temporary / interim"
  }.freeze

  SALARY_EMPLOYMENT_TYPES     = %w[employed].freeze
  PERCENTAGE_EMPLOYMENT_TYPES = %w[self_employed freelance].freeze

  SEARCH_STATUSES = {
    "active"   => "Active",
    "passive"  => "Passive",
    "inactive" => "Inactive"
  }.freeze

  TRANSPORT_TYPES = {
    "bike"             => "Bike",
    "scooter"          => "Scooter",
    "public_transport" => "Public transport",
    "car"              => "Car"
  }.freeze

  BIG_REGISTRATION_STATUSES = {
    "big_registered"   => "BIG registered",
    "in_progress"      => "In progress",
    "under_supervision" => "Under supervision",
    "not_applicable"   => "Not applicable"
  }.freeze

  BIG_REGISTERED_STATUS = "big_registered".freeze

  EDUCATION_LEVELS = {
    "mbo"      => "MBO",
    "hbo"      => "HBO",
    "bachelor" => "Bachelor",
    "master"   => "Master",
    "doctor"   => "Doctor",
    "course"   => "Course"
  }.freeze

  WORKING_DAYS = {
    "monday"    => "Monday",
    "tuesday"   => "Tuesday",
    "wednesday" => "Wednesday",
    "thursday"  => "Thursday",
    "friday"    => "Friday",
    "saturday"  => "Saturday",
    "sunday"    => "Sunday"
  }.freeze

  REGIONS = {
    "drenthe"       => "Drenthe",
    "flevoland"     => "Flevoland",
    "friesland"     => "Friesland",
    "gelderland"    => "Gelderland",
    "groningen"     => "Groningen",
    "limburg"       => "Limburg",
    "noord_brabant" => "Noord-Brabant",
    "noord_holland" => "Noord-Holland",
    "overijssel"    => "Overijssel",
    "utrecht"       => "Utrecht",
    "zeeland"       => "Zeeland",
    "zuid_holland"  => "Zuid-Holland"
  }.freeze

  LANGUAGE_LEVELS = {
    "basic"  => "Basic",
    "a1"     => "A1",
    "a2"     => "A2",
    "b1"     => "B1",
    "b2"     => "B2",
    "c1"     => "C1",
    "c2"     => "C2",
    "fluent" => "Fluent",
    "native" => "Native"
  }.freeze
end

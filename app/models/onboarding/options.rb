module Onboarding
  module Options
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

    SALARY_EMPLOYMENT_TYPES     = %w[employed temporary].freeze
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

    module_function

    def keys(collection)
      collection.keys
    end

    def label(collection, key)
      collection.fetch(key.to_s) { key.to_s.humanize }
    end

    def select(collection)
      collection.map { |key, label| [ label, key ] }
    end

    def skill_group_for(job_function)
      JOB_FUNCTION_TO_SKILL_GROUP[job_function.to_s]
    end

    def requires_big_registration?(job_function)
      BIG_REGISTRATION_FUNCTIONS.include?(job_function.to_s)
    end

    def revenue_relevant?(job_function)
      REVENUE_FUNCTIONS.include?(job_function.to_s)
    end

    def salary_relevant?(employment_types)
      Array(employment_types).intersect?(SALARY_EMPLOYMENT_TYPES)
    end

    def percentage_relevant?(employment_types)
      Array(employment_types).intersect?(PERCENTAGE_EMPLOYMENT_TYPES)
    end
  end
end

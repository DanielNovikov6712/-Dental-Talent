module Onboarding
  module Options
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
      Constants::JOB_FUNCTION_TO_SKILL_GROUP[job_function.to_s]
    end

    def requires_big_registration?(job_function)
      Constants::BIG_REGISTRATION_FUNCTIONS.include?(job_function.to_s)
    end

    def revenue_relevant?(job_function)
      Constants::REVENUE_FUNCTIONS.include?(job_function.to_s)
    end

    def salary_relevant?(employment_types)
      Array(employment_types).intersect?(Constants::SALARY_EMPLOYMENT_TYPES)
    end

    def percentage_relevant?(employment_types)
      Array(employment_types).intersect?(Constants::PERCENTAGE_EMPLOYMENT_TYPES)
    end
  end
end

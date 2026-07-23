class CreateCandidateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :candidate_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      t.string :status, null: false, default: "draft"

      # Personal details
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone_number
      t.string :city
      t.string :country

      # Job preferences
      t.string  :desired_job_function
      t.integer :max_travel_time
      t.string  :search_status
      t.text    :reason_for_looking
      t.json    :preferred_regions, default: []
      t.json    :transport_types, default: []

      # Employment & compensation
      t.json    :employment_types, default: []
      t.integer :desired_gross_salary
      t.decimal :desired_percentage, precision: 5, scale: 2
      t.decimal :average_daily_revenue, precision: 10, scale: 2
      t.string  :big_registration_status
      t.string  :big_number
      t.integer :years_of_experience

      # Availability
      t.json :available_working_days, default: []
      t.date :available_from
      t.string :notice_period

      # Additional information
      t.text :motivation
      t.text :internal_notes
      t.text :professional_summary

      # Consent (privacy)
      t.boolean  :consent_accepted, null: false, default: false
      t.datetime :consent_accepted_at

      # Onboarding bookkeeping
      t.json     :extracted_fields, default: []
      t.datetime :completed_at

      t.timestamps
    end
  end
end

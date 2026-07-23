class CreateCandidateSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :candidate_skills do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      # Nullable: unknown skills detected in a CV are stored as free-text
      # suggestions (no matching Skill record) for recruiter review.
      t.references :skill, null: true, foreign_key: true

      t.string  :name
      t.boolean :suggested, null: false, default: false
      t.boolean :from_cv, null: false, default: false

      t.timestamps
    end

    # NULL skill_id values are distinct in SQLite, so multiple free-text
    # suggestions per profile are allowed while matched skills stay unique.
    add_index :candidate_skills, [ :candidate_profile_id, :skill_id ], unique: true
  end
end

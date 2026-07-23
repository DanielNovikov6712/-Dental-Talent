class CreateCandidateLanguages < ActiveRecord::Migration[8.1]
  def change
    create_table :candidate_languages do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.references :language, null: true, foreign_key: true

      t.string  :name
      t.string  :level
      t.boolean :from_cv, null: false, default: false

      t.timestamps
    end

    add_index :candidate_languages, [ :candidate_profile_id, :language_id ], unique: true
  end
end

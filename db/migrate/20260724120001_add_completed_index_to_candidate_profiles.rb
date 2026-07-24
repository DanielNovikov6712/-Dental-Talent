class AddCompletedIndexToCandidateProfiles < ActiveRecord::Migration[8.1]
  def change
    add_index :candidate_profiles, %i[status completed_at],
      name: "index_candidate_profiles_on_status_and_completed_at"
  end
end

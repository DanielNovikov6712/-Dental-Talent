class CreateCandidateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :candidate_documents do |t|
      t.references :candidate_profile, null: false, foreign_key: true

      t.string   :document_type, null: false, default: "cv"
      t.string   :original_filename
      t.string   :content_type
      t.bigint   :file_size
      t.string   :parsing_status, null: false, default: "pending"
      t.datetime :parsed_at
      t.string   :parsing_error
      # Structured parser output kept server-side only (never exposed to candidates).
      t.json     :parsed_data

      t.timestamps
    end
  end
end

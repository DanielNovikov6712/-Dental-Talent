class EnforceNotNullOnProfileArrayColumns < ActiveRecord::Migration[8.1]
  COLUMNS = %i[
    preferred_regions transport_types employment_types
    available_working_days extracted_fields
  ].freeze

  def up
    COLUMNS.each do |column|
      execute("UPDATE candidate_profiles SET #{column} = '[]' WHERE #{column} IS NULL")
      change_column_null :candidate_profiles, column, false
    end
  end

  def down
    COLUMNS.each { |column| change_column_null :candidate_profiles, column, true }
  end
end

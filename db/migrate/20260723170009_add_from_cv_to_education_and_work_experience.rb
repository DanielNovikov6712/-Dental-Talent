class AddFromCvToEducationAndWorkExperience < ActiveRecord::Migration[8.1]
  def change
    add_column :educations, :from_cv, :boolean, null: false, default: false
    add_column :work_experiences, :from_cv, :boolean, null: false, default: false
  end
end

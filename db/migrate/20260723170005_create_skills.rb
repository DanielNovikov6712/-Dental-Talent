class CreateSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :skills do |t|
      t.string  :name, null: false
      t.string  :function_group, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :skills, :function_group
    add_index :skills, [ :function_group, :name ], unique: true
  end
end

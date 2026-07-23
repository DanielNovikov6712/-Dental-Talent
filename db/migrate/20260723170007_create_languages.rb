class CreateLanguages < ActiveRecord::Migration[8.1]
  def change
    create_table :languages do |t|
      t.string  :name, null: false
      t.string  :code
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :languages, :name, unique: true
  end
end

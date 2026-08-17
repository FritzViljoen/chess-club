class CreateContestResults < ActiveRecord::Migration[8.1]
  def change
    create_table :contest_results do |t|
      t.references :contest, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.integer :place, null: false

      t.timestamps
    end

    add_index :contest_results, [ :contest_id, :person_id ], unique: true
  end
end

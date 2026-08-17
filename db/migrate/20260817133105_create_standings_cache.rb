class CreateStandingsCache < ActiveRecord::Migration[8.1]
  def change
    create_table :standings_cache do |t|
      t.references :person, null: false, index: { unique: true }
      t.integer :position, null: false
    end

    add_index :standings_cache, :position, unique: true
  end
end

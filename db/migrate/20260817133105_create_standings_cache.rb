class CreateStandingsCache < ActiveRecord::Migration[8.1]
  def up
    create_table :standings_cache do |t|
      t.references :person, null: false, index: { unique: true }
      t.integer :position, null: false
    end

    add_index :standings_cache, :position, unique: true

    # A derived table starts empty and nothing fills it until somebody happens
    # to write, so a database that already holds people would show an empty
    # board — on the page this migration makes the root.
    RecalculateStandings.call
  end

  def down
    drop_table :standings_cache
  end
end

class CreateStandingsCache < ActiveRecord::Migration[8.1]
  def change
    # No timestamps: these rows are replaced wholesale on every write and nothing
    # ever asks when one was made.
    # No foreign key. Every row here is discarded and rewritten whenever the log
    # changes, so the whole table goes rather than one row being mended — and a
    # constraint that only ever fires between the delete and the recompute is an
    # obstacle to the recompute, not an invariant. What keeps this table honest
    # is that nothing reads it outside a transaction that has just rewritten it.
    create_table :standings_cache do |t|
      t.references :person, null: false, index: { unique: true }
      t.integer :position, null: false
    end

    add_index :standings_cache, :position, unique: true
  end
end

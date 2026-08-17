class CreateContests < ActiveRecord::Migration[8.1]
  def change
    create_table :contests do |t|
      t.datetime :played_at, null: false

      t.timestamps
    end

    add_index :contests, :played_at
  end
end

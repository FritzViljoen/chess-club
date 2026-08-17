class CreatePeople < ActiveRecord::Migration[8.1]
  def change
    create_table :people do |t|
      t.string :name, null: false
      t.string :surname, null: false
      t.string :email, null: false
      t.date :born_on, null: false
      t.date :joined_on, null: false

      t.timestamps
    end

    # Partial, because email is optional and no column is nullable: somebody
    # without one holds '', and a plain unique index would let the first such
    # person in and refuse the second. Unique among the people who have one.
    add_index :people, :email, unique: true, where: "email != ''"
  end
end

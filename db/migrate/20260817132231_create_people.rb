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

    add_index :people, :email, unique: true
  end
end

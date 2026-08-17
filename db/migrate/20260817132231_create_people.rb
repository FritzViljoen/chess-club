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

    # Email is how a person is identified from outside: the brief gives no
    # number to use instead, and `id` is this database's business rather than
    # anybody's way of naming somebody. So it is required and unique, and the
    # index is what makes that true rather than the validation.
    add_index :people, :email, unique: true
  end
end

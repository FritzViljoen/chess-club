require_relative "../cop_case"

class NoNullableColumnsTest < CopCase
  polices RuboCop::Cop::Schema::NoNullableColumns

  test "a new column with no null option is an offense" do
    assert_table_offense "t.string :email"
  end

  test "an explicitly nullable column is an offense" do
    assert_table_offense "t.string :email, null: true"
  end

  test "a column declared null: false is accepted" do
    assert_table_clean "t.string :email, null: false"
  end

  test "a generated column is held to the same rule" do
    assert_table_offense 't.virtual :slug, type: :string, as: "lower(name)", stored: true'
    assert_table_clean 't.virtual :slug, type: :string, as: "lower(name)", stored: true, null: false'
  end

  test "timestamps are accepted, being NOT NULL already" do
    assert_table_clean "t.timestamps"
    assert_migration_clean "add_timestamps :people"
  end

  test "timestamps reopened as nullable are an offense" do
    assert_table_offense "t.timestamps null: true"
    assert_migration_offense "add_timestamps :people, null: true"
    assert_migration_clean "add_timestamps :people, null: false"
  end

  test "add_column is held to the same rule" do
    assert_migration_offense "add_column :people, :surname, :string"
    assert_migration_clean "add_column :people, :surname, :string, null: false"
  end

  test "redefining a column is held to the same rule" do
    assert_migration_offense "change_column :people, :email, :text"
    assert_migration_offense "change_column :people, :email, :text, null: true"
    assert_migration_clean "change_column :people, :email, :text, null: false"
  end

  test "making an existing column nullable again is an offense" do
    assert_migration_offense "change_column_null :people, :email, true"
    assert_table_offense "t.change_null :email, true"
  end

  test "promoting a column to NOT NULL is accepted" do
    assert_migration_clean "change_column_null :people, :email, false"
    assert_table_clean "t.change_null :email, false"
  end

  test "a fill value does not disguise a promotion" do
    assert_migration_clean 'change_column_null :people, :email, false, ""'
  end

  test "the three steps in one method, in order, are accepted" do
    assert_migration_clean <<~RUBY
      add_column :people, :email, :string
      Person.update_all(email: "")
      change_column_null :people, :email, false
    RUBY
  end

  test "the three steps inside change_table are accepted" do
    assert_migration_clean <<~RUBY
      change_table :people do |t|
        t.string :email
        t.change_null :email, false
      end
    RUBY
  end

  test "a promotion before the column is added does not count" do
    assert_migration_offense <<~RUBY
      change_column_null :people, :email, false
      add_column :people, :email, :string
    RUBY
  end

  test "a promotion in another method does not count" do
    assert_class_offense <<~RUBY
      def up
        add_column :people, :email, :string
      end

      def down
        change_column_null :people, :email, false
      end
    RUBY
  end

  test "a promotion of some other column does not cover the new one" do
    assert_migration_offense <<~RUBY
      add_column :people, :email, :string
      change_column_null :people, :surname, false
    RUBY
  end

  test "a promotion on some other table does not cover the new column" do
    assert_migration_offense <<~RUBY
      add_column :people, :email, :string
      change_column_null :groups, :email, false
    RUBY
  end

  test "a reference is held to the same rule" do
    assert_table_offense "t.references :group"
    assert_table_clean "t.references :group, null: false"
    assert_migration_offense "add_reference :people, :group"
    assert_migration_clean "add_reference :people, :group, null: false"
  end

  test "a reference is promoted under the column it really creates" do
    assert_migration_clean <<~RUBY
      add_reference :people, :group
      Person.update_all(group_id: 1)
      change_column_null :people, :group_id, false
    RUBY
  end

  test "promoting a reference under its association name does not count" do
    assert_migration_offense <<~RUBY
      add_reference :people, :group
      change_column_null :people, :group, false
    RUBY
  end

  test "a polymorphic reference needs both of its columns promoted" do
    assert_migration_clean <<~RUBY
      add_reference :people, :owner, polymorphic: true
      change_column_null :people, :owner_id, false
      change_column_null :people, :owner_type, false
    RUBY

    assert_migration_offense <<~RUBY
      add_reference :people, :owner, polymorphic: true
      change_column_null :people, :owner_id, false
    RUBY
  end

  test "the reverse direction may restore a nullable column" do
    assert_class_clean <<~RUBY
      def up
        add_column :people, :email, :string, null: false
      end

      def down
        change_column_null :people, :email, true
        remove_column :people, :email
      end
    RUBY
  end

  test "a reversible block's down direction may restore a nullable column" do
    assert_migration_clean <<~RUBY
      reversible do |dir|
        dir.down { change_column_null :people, :email, true }
      end
    RUBY
  end

  test "every column of a multi-column definition is held to the rule" do
    assert_table_offense "t.string :email, :nickname"
    assert_table_clean "t.string :email, :nickname, null: false"
  end

  test "promoting one column of a multi-column definition does not cover the rest" do
    assert_migration_offense <<~RUBY
      change_table :people do |t|
        t.string :email, :nickname
        t.change_null :email, false
      end
    RUBY

    assert_migration_clean <<~RUBY
      change_table :people do |t|
        t.string :email, :nickname
        t.change_null :email, false
        t.change_null :nickname, false
      end
    RUBY
  end

  test "promoting one column of a multi-reference does not cover the rest" do
    assert_migration_offense <<~RUBY
      change_table :items do |t|
        t.references :group, :category
        t.change_null :group_id, false
      end
    RUBY

    assert_migration_clean <<~RUBY
      change_table :items do |t|
        t.references :group, :category
        t.change_null :group_id, false
        t.change_null :category_id, false
      end
    RUBY
  end

  test "a type argument is not mistaken for a second column" do
    assert_table_offense "t.column :email, :string"
    assert_migration_clean <<~RUBY
      change_table :people do |t|
        t.column :email, :string
        t.change_null :email, false
      end
    RUBY
  end

  test "a drop_table block describes the rollback and is left alone" do
    assert_migration_clean <<~RUBY
      drop_table :people do |t|
        t.string :email
        t.integer :score, null: false, default: 1200
      end
    RUBY
  end

  test "a promotion in the reverse direction does not promote the forward one" do
    assert_migration_offense <<~RUBY
      add_column :people, :handle, :string
      reversible do |dir|
        dir.down { change_column_null :people, :handle, false }
      end
    RUBY
  end

  test "a same-named method on another receiver is left alone" do
    assert_migration_clean "Kernel.string :email"
    assert_migration_clean "helper.add_column :people, :surname, :string"
  end

  test "a local that is not the yielded table object is left alone" do
    assert_migration_clean <<~RUBY
      cutoff = Time.current
      Person.where("created_at < ?", cutoff.change(hour: 0)).delete_all
    RUBY
  end

  test "the table object is still recognised inside its own block" do
    assert_migration_offense <<~RUBY
      change_table :people do |t|
        t.change :email, :text
      end
    RUBY
  end
end

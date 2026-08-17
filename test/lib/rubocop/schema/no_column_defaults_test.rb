require_relative "../cop_case"

class NoColumnDefaultsTest < CopCase
  polices RuboCop::Cop::Schema::NoColumnDefaults

  test "a default on a new column is an offense" do
    assert_table_offense "t.integer :attempts, null: false, default: 0"
    assert_migration_offense "add_column :people, :attempts, :integer, null: false, default: 0"
  end

  test "a column without a default is accepted" do
    assert_table_clean "t.integer :attempts, null: false"
    assert_migration_clean "add_column :people, :attempts, :integer, null: false"
  end

  test "timestamps may carry a default, being the one exception" do
    assert_table_clean "t.timestamps"
    assert_table_clean 't.timestamps default: -> { "CURRENT_TIMESTAMP" }'
    assert_migration_clean 'add_timestamps :people, default: -> { "CURRENT_TIMESTAMP" }'
  end

  test "a default introduced while redefining a column is an offense" do
    assert_migration_offense "change_column :people, :attempts, :integer, default: 0"
    assert_migration_clean "change_column :people, :attempts, :integer, null: false"
  end

  test "giving an existing column a default is an offense" do
    assert_migration_offense "change_column_default :people, :attempts, from: nil, to: 0"
    assert_migration_offense "change_column_default :people, :attempts, 0"
    assert_table_offense "t.change_default :attempts, 0"
  end

  test "taking a default away is accepted" do
    assert_migration_clean "change_column_default :people, :attempts, from: 0, to: nil"
    assert_migration_clean "change_column_default :people, :attempts, nil"
    assert_table_clean "t.change_default :attempts, nil"
  end

  test "the reverse direction may restore a default" do
    assert_class_clean <<~RUBY
      def up
        change_column_default :people, :attempts, from: 0, to: nil
      end

      def down
        change_column_default :people, :attempts, from: nil, to: 0
      end
    RUBY
  end

  test "a same-named method on another receiver is left alone" do
    assert_migration_clean "Kernel.integer :attempts, default: 0"
    assert_migration_clean "helper.change_column_default :people, :attempts, to: 0"
  end
end

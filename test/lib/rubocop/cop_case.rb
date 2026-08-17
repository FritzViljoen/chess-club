require "test_helper"
require "rubocop"
require_relative "../../../lib/rubocop/schema"
require_relative "../../../lib/rubocop/model"
require_relative "../../../lib/rubocop/vocabulary"

# Base class for the house-cop tests.
#
# A subclass names its cop with `polices`, then asserts on a fragment of
# migration source: `table` wraps it in a `create_table` block, `migration`
# uses it as the migration body as written. A cop that reads somewhere other
# than db/migrate says so with `on_path`, and one that takes settings from
# .rubocop.yml declares them with `configured`.
class CopCase < ActiveSupport::TestCase
  # Both cops only look at migrations, and rubocop-rails silently skips
  # offenses in any file whose timestamp is at or below `MigratedSchemaVersion`
  # — the UNIX epoch by default — so every example needs a plausible one.
  MIGRATION_PATH = "db/migrate/20260817120000_example.rb"

  class_attribute :cop_class
  # The path rubocop is told the source came from. Cops scoped to somewhere
  # other than db/migrate say so with `on_path`.
  class_attribute :source_path, default: MIGRATION_PATH
  # Cop settings that would come from .rubocop.yml, beyond `Enabled`.
  class_attribute :cop_settings, default: {}

  def self.polices(cop_class)
    self.cop_class = cop_class
  end

  def self.on_path(path)
    self.source_path = path
  end

  def self.configured(settings)
    self.cop_settings = settings
  end

  private
    # One offense expected, on a single line inside a `create_table` block.
    def assert_table_offense(line)
      assert_offenses table(line), 1
    end

    def assert_table_clean(line)
      assert_offenses table(line), 0
    end

    def assert_migration_offense(body, count: 1)
      assert_offenses migration(body), count
    end

    def assert_migration_clean(body)
      assert_offenses migration(body), 0
    end

    # For examples that need their own method structure — `up` and `down`, or a
    # `reversible` block — rather than the single `change` the others get.
    def assert_class_offense(methods, count: 1)
      assert_offenses migration_class(methods), count
    end

    def assert_class_clean(methods)
      assert_offenses migration_class(methods), 0
    end

    def assert_offenses(source, expected)
      found = offenses(source)
      assert_equal expected, found.size,
        "#{cop_class.badge} on\n#{source}\nexpected #{expected} offense(s), " \
        "got #{found.size}: #{found.map(&:message)}"
    end

    def offenses(source)
      config = RuboCop::Config.new(
        { cop_class.badge.to_s => { "Enabled" => true }.merge(cop_settings) },
        Rails.root.join(".rubocop.yml").to_s)
      processed = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f, source_path)

      RuboCop::Cop::Commissioner.new([ cop_class.new(config) ]).investigate(processed).offenses
    end

    def table(line)
      migration(<<~RUBY)
        create_table :people do |t|
        #{line.indent(2)}
        end
      RUBY
    end

    def migration(body)
      migration_class(<<~RUBY)
        def change
        #{body.indent(2)}
        end
      RUBY
    end

    def migration_class(methods)
      <<~RUBY
        class Example < ActiveRecord::Migration[8.1]
        #{methods.indent(2)}
        end
      RUBY
    end
end

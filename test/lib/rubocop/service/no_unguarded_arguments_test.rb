require_relative "../cop_case"

class NoUnguardedArgumentsTest < CopCase
  polices RuboCop::Cop::Service::NoUnguardedArguments
  on_path "app/services/archive_round.rb"

  test "an unguarded keyword is an offense" do
    assert_source_offense <<~RUBY
      class ArchiveRound < Service
        def initialize(on:)
          @on = on
        end
      end
    RUBY
  end

  test "each of the guards counts as one" do
    assert_source_clean <<~RUBY
      class ArchiveRound < Service
        def initialize(round:, at:, kind:, entrants:, counts:)
          @round = typed(round, Round)
          @at = typed(at, ActiveSupport::TimeWithZone)
          @kind = typed_enum(kind, KINDS)
          @entrants = typed_array(entrants, Person)
          @counts = typed_hash(counts, key: String, value: Integer)
        end
      end
    RUBY
  end

  test "a namespaced base is the same base" do
    assert_source_offense <<~RUBY
      class Rounds::Archive < Rounds::Service
        def initialize(on:)
          @on = on
        end
      end
    RUBY
  end

  test "a class that is not a service is not this cop's business" do
    assert_source_clean <<~RUBY
      class Round < ApplicationRecord
        def initialize(on:)
          @on = on
        end
      end
    RUBY
  end

  test "a method that is not the initializer is not checked" do
    assert_source_clean <<~RUBY
      class ArchiveRound < Service
        def call(on:)
          @on = on
        end
      end
    RUBY
  end

  test "a keyword with a default still needs its guard" do
    assert_source_offense <<~RUBY
      class ArchiveRound < Service
        def initialize(on: Date.new)
          @on = on
        end
      end
    RUBY
  end

  test "a guard on some other value does not cover this keyword" do
    assert_source_offense <<~RUBY
      class ArchiveRound < Service
        def initialize(on:, round:)
          @round = typed(round, Round)
          @on = typed(round.starts_on, Date)
        end
      end
    RUBY
  end

  test "every unguarded keyword is reported, not just the first" do
    assert_source_offense <<~RUBY, count: 2
      class ArchiveRound < Service
        def initialize(on:, round:)
          @on = on
          @round = round
        end
      end
    RUBY
  end

  test "the message names the keyword that is unguarded" do
    source = <<~RUBY
      class ArchiveRound < Service
        def initialize(on:)
          @on = on
        end
      end
    RUBY

    assert_includes offenses(source).first.message, "`on`"
  end

  test "a rest parameter takes untyped keywords, so it is an offense" do
    assert_source_offense <<~RUBY
      class ArchiveRound < Service
        def initialize(**options)
          @options = options
        end
      end
    RUBY
  end

  test "a rest parameter is an offense even beside guarded keywords" do
    assert_source_offense <<~RUBY
      class ArchiveRound < Service
        def initialize(round:, **options)
          @round = typed(round, Round)
          @options = options
        end
      end
    RUBY
  end

  test "a positional parameter collects what no guard can name" do
    assert_source_offense <<~RUBY
      class ArchiveRound < Service
        def initialize(*args)
          @args = args
        end
      end
    RUBY
  end

  test "a positional hash is the same hole with a friendlier face" do
    assert_source_offense <<~RUBY
      class ArchiveRound < Service
        def initialize(options = {})
          @options = options
        end
      end
    RUBY

    assert_source_offense <<~RUBY
      class ArchiveRound < Service
        def initialize(round)
          @round = typed(round, Round)
        end
      end
    RUBY
  end

  test "forwarding everything guards nothing" do
    assert_source_offense <<~RUBY
      class ArchiveRound < Service
        def initialize(...)
          @built = true
        end
      end
    RUBY
  end

  test "an initializer taking nothing is clean" do
    assert_source_clean <<~RUBY
      class ArchiveRound < Service
        def initialize
          @on = Date.current
        end
      end
    RUBY
  end
end

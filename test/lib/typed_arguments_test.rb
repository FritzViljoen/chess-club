require "test_helper"

class TypedArgumentsTest < ActiveSupport::TestCase
  # `typed` and its siblings are private, so a caller reaches them the way a
  # base class does: by including the module.
  class Guarded
    include TypedArguments

    public :typed, :typed_enum, :typed_array, :typed_hash
  end

  ALLOWED = %i[first second].freeze
  ZONE = ActiveSupport::TimeZone["Africa/Johannesburg"]

  setup { @guard = Guarded.new }

  test "typed returns a value of the named type" do
    assert_equal "ready", @guard.typed("ready", String)
  end

  test "typed accepts a subclass of the named type" do
    assert_equal 3, @guard.typed(3, Numeric)
  end

  test "typed rejects a value of another type" do
    error = assert_raises(ArgumentError) { @guard.typed(3, String) }

    assert_equal "expected String, got Integer", error.message
  end

  test "typed rejects nil" do
    error = assert_raises(ArgumentError) { @guard.typed(nil, String) }

    assert_equal "expected String, got NilClass", error.message
  end

  test "typed accepts nil only when the caller allows it" do
    assert_nil @guard.typed(nil, String, allow_nil: true)
  end

  test "typed does not coerce" do
    error = assert_raises(ArgumentError) { @guard.typed("3", Integer) }

    assert_equal "expected Integer, got String", error.message
  end

  test "a time argument is asserted as the time that carries its zone" do
    at = ZONE.parse("2026-08-17 10:30")

    assert_equal at, @guard.typed(at, ActiveSupport::TimeWithZone)
    assert_raises(ArgumentError) { @guard.typed(Time.utc(2026, 8, 17, 10, 30), ActiveSupport::TimeWithZone) }
  end

  test "typed refuses to assert a time class that names no zone" do
    error = assert_raises(ArgumentError) { @guard.typed(ZONE.parse("2026-08-17 10:30"), Time) }

    assert_equal "assert ActiveSupport::TimeWithZone (or a String for a wall-clock reading), " \
                 "not Time — a Time names no zone", error.message
    assert_raises(ArgumentError) { @guard.typed(nil, DateTime) }
  end

  # A DateTime is a Date, and everything is an Object.
  test "a zoneless time is refused whatever type it was asserted as" do
    error = assert_raises(ArgumentError) { @guard.typed(DateTime.parse("2026-08-17T10:30:00+05:00"), Date) }

    assert_equal "assert ActiveSupport::TimeWithZone (or a String for a wall-clock reading) — " \
                 "a DateTime names no zone", error.message
    assert_raises(ArgumentError) { @guard.typed(Time.utc(2026, 8, 17), Object) }
    assert_raises(ArgumentError) { @guard.typed(Time.utc(2026, 8, 17), Comparable) }
  end

  # `TimeWithZone` answers true to `is_a?(Time)`, which is how the check above
  # could have been fooled.
  test "a time that carries its zone is not caught by the refusal of ones that do not" do
    at = ZONE.parse("2026-08-17 10:30")

    assert at.is_a?(Time), "TimeWithZone no longer answers to Time, so the exclusion may be moot"
    assert_equal at, @guard.typed(at, ActiveSupport::TimeWithZone)
    assert_equal at, @guard.typed(at, Object)
  end

  test "a collection hiding a zoneless time is refused element by element" do
    assert_raises(ArgumentError) { @guard.typed_array([ DateTime.new(2026, 8, 17) ], Date) }
    assert_raises(ArgumentError) { @guard.typed_hash({ "a" => Time.utc(2026) }, key: String, value: Object) }
    assert_raises(ArgumentError) { @guard.typed_hash({ Time.utc(2026) => 1 }, key: Object, value: Integer) }
  end

  test "a collection of them is refused the same way" do
    assert_raises(ArgumentError) { @guard.typed_array([ ZONE.now ], Time) }
    assert_raises(ArgumentError) { @guard.typed_hash({ "a" => ZONE.now }, key: String, value: Time) }
    assert_raises(ArgumentError) { @guard.typed_hash({ ZONE.now => 1 }, key: Time, value: Integer) }
  end

  test "a collection of zoned times is asserted like any other" do
    times = [ ZONE.parse("2026-08-17 10:30") ]

    assert_equal times, @guard.typed_array(times, ActiveSupport::TimeWithZone)
  end

  test "a wall-clock reading is a string, not a time nobody can place" do
    assert_equal "18:30", @guard.typed("18:30", String)
  end

  test "a date has no zone to name, so typed asserts it as normal" do
    assert_equal Date.new(2026, 8, 17), @guard.typed(Date.new(2026, 8, 17), Date)
  end

  test "typed_enum returns a value from the allowed set" do
    assert_equal :first, @guard.typed_enum(:first, ALLOWED)
  end

  test "typed_enum rejects a value outside the allowed set" do
    error = assert_raises(ArgumentError) { @guard.typed_enum(:third, ALLOWED) }

    assert_equal "expected one of first, second, got :third", error.message
  end

  test "typed_enum rejects nil unless the caller allows it" do
    assert_raises(ArgumentError) { @guard.typed_enum(nil, ALLOWED) }
    assert_nil @guard.typed_enum(nil, ALLOWED, allow_nil: true)
  end

  test "typed_array returns an array whose every element is the named type" do
    assert_equal [ 1, 2 ], @guard.typed_array([ 1, 2 ], Integer)
  end

  test "typed_array accepts an empty array" do
    assert_equal [], @guard.typed_array([], Integer)
  end

  test "typed_array rejects something that is not an array" do
    error = assert_raises(ArgumentError) { @guard.typed_array(1, Integer) }

    assert_equal "expected Array of Integer, got Integer", error.message
  end

  test "typed_array names the position of the element that failed" do
    error = assert_raises(ArgumentError) { @guard.typed_array([ 1, "2" ], Integer) }

    assert_equal "expected Array of Integer, got String at index 1", error.message
  end

  test "typed_array rejects nil unless the caller allows it" do
    assert_raises(ArgumentError) { @guard.typed_array(nil, Integer) }
    assert_nil @guard.typed_array(nil, Integer, allow_nil: true)
  end

  test "typed_hash returns a hash whose keys and values are the named types" do
    counts = { "a" => 1 }

    assert_equal counts, @guard.typed_hash(counts, key: String, value: Integer)
  end

  test "typed_hash accepts an empty hash" do
    assert_equal({}, @guard.typed_hash({}, key: String, value: Integer))
  end

  test "typed_hash rejects something that is not a hash" do
    error = assert_raises(ArgumentError) { @guard.typed_hash([], key: String, value: Integer) }

    assert_equal "expected Hash of String => Integer, got Array", error.message
  end

  test "typed_hash names the key that failed" do
    error = assert_raises(ArgumentError) { @guard.typed_hash({ 1 => 1 }, key: String, value: Integer) }

    assert_equal "expected Hash of String => Integer, got Integer key 1", error.message
  end

  test "typed_hash names the key whose value failed" do
    error = assert_raises(ArgumentError) { @guard.typed_hash({ "a" => "1" }, key: String, value: Integer) }

    assert_equal 'expected Hash of String => Integer, got String value at key "a"', error.message
  end

  test "typed_hash rejects nil unless the caller allows it" do
    assert_raises(ArgumentError) { @guard.typed_hash(nil, key: String, value: Integer) }
    assert_nil @guard.typed_hash(nil, key: String, value: Integer, allow_nil: true)
  end
end

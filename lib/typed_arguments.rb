# frozen_string_literal: true

# Type guards for a service's arguments, asserted inline in a hand-written
# initializer:
#
#   def initialize(round:, on:, at:)
#     @round = typed(round, Round)
#     @on    = typed(on, Date)
#     @at    = typed(at, ActiveSupport::TimeWithZone)
#   end
#
# It asserts and never coerces — parsing is the seam's job (`TypedParams`). A
# mismatch is a caller defect and raises `ArgumentError`; a broken domain rule is
# not, and comes back as the service's `failure(:code)`.
#
# **The boundary is the point.** Past the initializer every value is already what
# it claims to be, so the body is written for values that are right — no nil
# checks, no re-parsing, no rescue for an argument that arrived wrong. And a
# failure has a side: at the guard it is the caller's defect, past it the
# object's own.
#
# `nil` is a mismatch like any other; `allow_nil: true` says otherwise, at the
# argument that permits it. One type per argument — name a shared ancestor
# (`Numeric`) or the `Boolean` marker rather than a union.
#
# A time is an `ActiveSupport::TimeWithZone`. `Time` and `DateTime` are refused,
# as a declared type and as a value, because their offset is whatever the process
# had. A wall-clock reading that is not a moment — "18:30" — is a String; a
# `Time` built to hold one invents a date and an offset it never had.
#
# `typed_array` and `typed_hash` check the collection and every element.
# `typed_hash` names one key type and one value type, so it fits a lookup index
# and nothing else; anything richer is an object nobody has named yet. For an
# element check no signature expresses, use a block — `each` returns the
# receiver, so the assignment stays one line:
#
#   @kinds = typed(kinds, Array).each { |kind| typed_enum(kind, KINDS) }
#
# There is no duck-type escape hatch. `respond_to?(:starts_on)` asserts a method
# name rather than a type, and invites taking a whole record to read one field
# off it. Name the value actually used and pass that.
module TypedArguments
  # Refused as a type and as a value: neither says which zone it is in.
  ZONELESS_TIMES = [ Time, DateTime ].freeze

  ADVICE = "assert ActiveSupport::TimeWithZone (or a String for a wall-clock reading)"

  private
    def typed(value, type, allow_nil: false)
      refuse_zoneless_time(type)
      return value if value.nil? && allow_nil

      refuse_zoneless_value(value)
      return value if value.is_a?(type)

      raise ArgumentError, "expected #{type}, got #{value.class}"
    end

    # A closed set of literal values rather than a class.
    def typed_enum(value, allowed, allow_nil: false)
      return value if value.nil? && allow_nil
      return value if allowed.include?(value)

      raise ArgumentError, "expected one of #{allowed.join(", ")}, got #{value.inspect}"
    end

    # An Array whose every element is `type`. Empty passes — how many elements a
    # collection needs is a rule, not a type. The index is in the message because
    # the class alone names neither the argument nor the position.
    def typed_array(value, type, allow_nil: false)
      refuse_zoneless_time(type)
      return value if value.nil? && allow_nil

      expected = "expected Array of #{type}"
      raise ArgumentError, "#{expected}, got #{value.class}" unless value.is_a?(Array)

      value.each_with_index do |element, index|
        refuse_zoneless_value(element)
        next if element.is_a?(type)

        raise ArgumentError, "#{expected}, got #{element.class} at index #{index}"
      end
    end

    # A Hash mapping `key` to `value`. Named types, because
    # `typed_hash(counts, String, Integer)` does not say which is which.
    def typed_hash(hash, key:, value:, allow_nil: false)
      refuse_zoneless_time(key)
      refuse_zoneless_time(value)
      return hash if hash.nil? && allow_nil

      expected = "expected Hash of #{key} => #{value}"
      raise ArgumentError, "#{expected}, got #{hash.class}" unless hash.is_a?(Hash)

      hash.each do |hash_key, hash_value|
        refuse_zoneless_value(hash_key)
        refuse_zoneless_value(hash_value)
        raise ArgumentError, "#{expected}, got #{hash_key.class} key #{hash_key.inspect}" unless hash_key.is_a?(key)
        next if hash_value.is_a?(value)

        raise ArgumentError, "#{expected}, got #{hash_value.class} value at key #{hash_key.inspect}"
      end
    end

    def refuse_zoneless_time(type)
      return unless ZONELESS_TIMES.include?(type)

      raise ArgumentError, "#{ADVICE}, not #{type} — a #{type} names no zone"
    end

    # Refusing only the declared type would let the value in through any type it
    # satisfies — `DateTime` is a `Date`, everything is an `Object`.
    #
    # `TimeWithZone` is let past first, and must be: it answers `true` to
    # `is_a?(Time)` deliberately, so it can stand in for one.
    def refuse_zoneless_value(value)
      return if value.is_a?(ActiveSupport::TimeWithZone)
      return unless ZONELESS_TIMES.any? { |type| value.is_a?(type) }

      raise ArgumentError, "#{ADVICE} — a #{value.class} names no zone"
    end
end

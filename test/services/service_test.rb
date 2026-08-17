require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  class ArchiveRound < Service
    def initialize(score:)
      @score = typed(score, Integer)
    end

    def call
      return failure(:out_of_range) unless @score.between?(0, 2)

      success(@score)
    end
  end

  class RoundStanding < Service
    def initialize(count:)
      @count = typed(count, Integer)
    end

    def call
      success((1..@count).to_a)
    end
  end

  class Sloppy < Service
    def call
      :done
    end
  end

  test "a service that did the work answers with its value" do
    result = ArchiveRound.call(score: 2)

    assert_predicate result, :success?
    assert_equal 2, result.value
    assert_nil result.error
  end

  test "a refusal comes back as a code the caller can handle" do
    result = ArchiveRound.call(score: 9)

    assert_not_predicate result, :success?
    assert_equal :out_of_range, result.error
    assert_nil result.value
  end

  test "a service that reads answers the same way, with its data" do
    result = RoundStanding.call(count: 3)

    assert_predicate result, :success?
    assert_equal [ 1, 2, 3 ], result.value
  end

  test "an empty answer is data, not a refusal" do
    result = RoundStanding.call(count: 0)

    assert_predicate result, :success?
    assert_equal [], result.value
  end

  test "a service asserts the types of its arguments" do
    error = assert_raises(ArgumentError) { ArchiveRound.call(score: "2") }

    assert_equal "expected Integer, got String", error.message
  end

  test "returning anything but a result is a defect, and says so" do
    error = assert_raises(TypeError) { Sloppy.call }

    assert_equal "ServiceTest::Sloppy#call must return a Result", error.message
  end

  test "a successful result carries no error and a refused one carries no value" do
    assert_predicate Service::Result.success(:anything), :success?
    assert_not_predicate Service::Result.failure(:code), :success?
  end
end

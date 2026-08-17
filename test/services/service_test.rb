require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  class AddRound < Service
    def initialize(name:)
      @name = typed(name, String)
    end

    def call
      person = Person.new(
        name: @name, surname: "Baker", email: "#{@name}@example.test",
        born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 5)
      )
      person.save

      person
    end
  end

  class RoundStanding < Service
    def initialize(rows:)
      @rows = typed_array(rows, Integer)
    end

    def call
      @rows
    end
  end

  test "a service answers with the thing it made" do
    person = AddRound.call(name: "Ann")

    assert_equal "Ann", person.name
    assert person.persisted?
  end

  test "a refused write answers with the record, and the record says why" do
    AddRound.call(name: "Ann")

    repeated = AddRound.call(name: "Ann")

    assert_not repeated.persisted?, "expected the duplicate not to be stored"
    assert repeated.errors.any?, "expected the record to carry why it was refused"
    assert_includes repeated.errors[:email], "has already been taken"
  end

  test "errors.none? is what a caller asks, either way" do
    accepted = AddRound.call(name: "Bo")

    assert accepted.errors.none?
  end

  test "a service that reads answers with its data" do
    assert_equal [ 1, 2, 3 ], RoundStanding.call(rows: [ 1, 2, 3 ])
  end

  test "an empty answer is data, not a refusal" do
    assert_equal [], RoundStanding.call(rows: [])
  end

  test "an argument of the wrong type is the caller's defect, and raises" do
    assert_raises(ArgumentError) { AddRound.call(name: 42) }
    assert_raises(ArgumentError) { RoundStanding.call(rows: [ "1" ]) }
  end

  test "call constructs with the keywords it was given" do
    assert_equal [ 7 ], RoundStanding.call(rows: [ 7 ]), "expected .call to reach initialize"
  end
end

require "test_helper"

class ReadStandingsTest < ActiveSupport::TestCase
  test "answers with the rows in position order" do
    first = create_person("a@example.test", 0)
    second = create_person("b@example.test", 1)

    rows = ReadStandings.call.value

    assert_equal [ first.id, second.id ], rows.map(&:person_id),
      "expected position 1 to come back first"
  end

  test "answers with an empty list rather than a refusal when nobody has joined" do
    result = ReadStandings.call

    assert result.success?, "expected an empty standings to be an answer, not a refusal"
    assert_empty result.value
  end

  private
    def create_person(email, offset)
      CreatePerson.call(
        name: "Ann", surname: "Baker", email: email,
        born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 1) + offset
      ).value
    end
end

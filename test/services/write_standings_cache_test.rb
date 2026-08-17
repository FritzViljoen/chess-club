require "test_helper"

class WriteStandingsCacheTest < ActiveSupport::TestCase
  test "writes each person at the position it was handed" do
    first = person("a@example.test")
    second = person("b@example.test")

    WriteStandingsCache.call(standings: [
      Standing[person_id: first.id, position: 1],
      Standing[person_id: second.id, position: 2]
    ])

    assert_equal [ [ first.id, 1 ], [ second.id, 2 ] ],
      StandingsCache.order(:position).pluck(:person_id, :position),
      "expected the rows to hold the positions given, not ones counted off"
  end

  test "does not renumber what it is given" do
    first = person("a@example.test")
    second = person("b@example.test")

    WriteStandingsCache.call(standings: [
      Standing[person_id: first.id, position: 2],
      Standing[person_id: second.id, position: 1]
    ])

    assert_equal [ [ second.id, 1 ], [ first.id, 2 ] ],
      StandingsCache.order(:position).pluck(:person_id, :position),
      "expected the writer to persist positions rather than derive them from order"
  end

  test "replaces whatever was there before" do
    first = person("a@example.test")
    second = person("b@example.test")
    WriteStandingsCache.call(standings: [
      Standing[person_id: first.id, position: 1], Standing[person_id: second.id, position: 2]
    ])

    WriteStandingsCache.call(standings: [
      Standing[person_id: second.id, position: 1], Standing[person_id: first.id, position: 2]
    ])

    assert_equal [ second.id, first.id ], StandingsCache.order(:position).pluck(:person_id),
      "expected the second write to replace the first, not add to it"
    assert_equal 2, StandingsCache.count, "expected no rows left over from the first write"
  end

  test "empties the table when handed nothing" do
    WriteStandingsCache.call(standings: [ Standing[person_id: person("a@example.test").id, position: 1] ])

    WriteStandingsCache.call(standings: [])

    assert_equal 0, StandingsCache.count, "expected an empty standings to leave no rows"
  end

  test "refuses anything that is not a standing" do
    assert_raises(ArgumentError, "expected a bare pair to be a caller defect") do
      WriteStandingsCache.call(standings: [ [ person("a@example.test").id, 1 ] ])
    end
  end

  private
    def person(email)
      CreatePerson.call(
        name: "Ann", surname: "Baker", email: email,
        born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 5)
      ).value
    end
end

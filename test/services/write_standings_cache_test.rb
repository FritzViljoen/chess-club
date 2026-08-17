require "test_helper"

class WriteStandingsCacheTest < ActiveSupport::TestCase
  test "writes each person at the position it was handed" do
    first = create_person(email: "a@example.test")
    second = create_person(email: "b@example.test")

    WriteStandingsCache.call(standings: [
      Standing.new(person_id: first.id, position: 1),
      Standing.new(person_id: second.id, position: 2)
    ])

    assert_equal [ [ first.id, 1 ], [ second.id, 2 ] ],
      StandingsCache.order(:position).pluck(:person_id, :position),
      "expected the rows to hold the positions given, not ones counted off"
  end

  test "does not renumber what it is given" do
    first = create_person(email: "a@example.test")
    second = create_person(email: "b@example.test")

    WriteStandingsCache.call(standings: [
      Standing.new(person_id: first.id, position: 2),
      Standing.new(person_id: second.id, position: 1)
    ])

    assert_equal [ [ second.id, 1 ], [ first.id, 2 ] ],
      StandingsCache.order(:position).pluck(:person_id, :position),
      "expected the writer to persist positions rather than derive them from order"
  end

  test "replaces whatever was there before" do
    first = create_person(email: "a@example.test")
    second = create_person(email: "b@example.test")
    WriteStandingsCache.call(standings: [
      Standing.new(person_id: first.id, position: 1), Standing.new(person_id: second.id, position: 2)
    ])

    WriteStandingsCache.call(standings: [
      Standing.new(person_id: second.id, position: 1), Standing.new(person_id: first.id, position: 2)
    ])

    assert_equal [ second.id, first.id ], StandingsCache.order(:position).pluck(:person_id),
      "expected the second write to replace the first, not add to it"
    assert_equal 2, StandingsCache.count, "expected no rows left over from the first write"
  end

  test "empties the table when handed nothing" do
    WriteStandingsCache.call(standings: [ Standing.new(person_id: create_person(email: "a@example.test").id, position: 1) ])

    WriteStandingsCache.call(standings: [])

    assert_equal 0, StandingsCache.count, "expected an empty standings to leave no rows"
  end

  test "refuses anything that is not a standing" do
    assert_raises(ArgumentError, "expected a bare pair to be a caller defect") do
      WriteStandingsCache.call(standings: [ [ create_person(email: "a@example.test").id, 1 ] ])
    end
  end

  private
    def create_person(email:, name: "Ann", surname: "Baker",
                      born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 5))
      CreatePerson.call(
        name: name, surname: surname, email: email,
        born_on: born_on, joined_on: joined_on
      )
    end
end

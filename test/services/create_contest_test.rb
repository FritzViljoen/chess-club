require "test_helper"

class CreateContestTest < ActiveSupport::TestCase
  test "moves the standings when the lower-placed person wins" do
    people = 4.times.map { |index| create_person("p#{index}@example.test", index) }

    CreateContest.call(played_at: at("2026-03-03 18:00"), winner: people[3], loser: people[0], tie: false)

    assert_equal [ people[1], people[0], people[3], people[2] ].map(&:id),
      StandingsCache.order(:position).pluck(:person_id),
      "expected the loser to drop one and the winner to climb one"
  end

  test "leaves the standings alone when the better-placed person wins" do
    people = 4.times.map { |index| create_person("p#{index}@example.test", index) }

    CreateContest.call(played_at: at("2026-03-03 18:00"), winner: people[0], loser: people[3], tie: false)

    assert_equal people.map(&:id), StandingsCache.order(:position).pluck(:person_id),
      "expected the expected result to move nobody"
  end

  test "refuses one person against themselves" do
    person = create_person("a@example.test", 0)

    result = CreateContest.call(played_at: at("2026-03-03 18:00"), winner: person, loser: person, tie: false)

    assert_not result.success?, "expected a person against themselves to be refused"
    assert_equal :invalid, result.error
  end

  private
    def at(literal)
      LocalZone.zone.parse(literal)
    end

    def create_person(email, offset)
      CreatePerson.call(
        name: "Ann", surname: "Baker", email: email,
        born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 1) + offset
      ).value
    end
end

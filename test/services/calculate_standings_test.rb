require "test_helper"

class CalculateStandingsTest < ActiveSupport::TestCase
  test "seeds people in join order, earliest first" do
    order = calculate(people: [ person(2, "2026-02-01"), person(1, "2026-01-01") ])

    assert_equal [ 1, 2 ], order, "expected the earlier joiner to start ahead"
  end

  test "breaks a shared join date by id" do
    order = calculate(people: [ person(9, "2026-01-01"), person(4, "2026-01-01") ])

    assert_equal [ 4, 9 ], order, "expected the lower id to start ahead on a shared date"
  end

  test "nothing moves when the better-positioned person wins" do
    order = calculate(people: ladder(4), contest_results: contest(winner: 1, loser: 3))

    assert_equal [ 1, 2, 3, 4 ], order, "expected the expected result to move nobody"
  end

  test "a tie moves the worse-positioned person up one" do
    order = calculate(people: ladder(6), contest_results: contest(winner: 2, loser: 5, tie: true))

    assert_equal [ 1, 2, 3, 5, 4, 6 ], order, "expected the lower person to gain one place"
  end

  test "a tie between adjacent people moves nobody" do
    order = calculate(people: ladder(4), contest_results: contest(winner: 2, loser: 3, tie: true))

    assert_equal [ 1, 2, 3, 4 ], order, "expected adjacent people to stay put on a tie"
  end

  test "the brief's worked example" do
    order = calculate(people: ladder(7), contest_results: contest(winner: 7, loser: 1))

    assert_equal [ 2, 1, 3, 7, 4, 5, 6 ], order,
      "expected the loser on position 2 and the winner on position 4"
  end

  test "an odd gap rounds the climb down" do
    order = calculate(people: ladder(6), contest_results: contest(winner: 6, loser: 1))

    assert_equal [ 2, 1, 3, 6, 4, 5 ], order, "expected a climb of 2, not 3, from a gap of 5"
  end

  test "a gap of two demotes and caps the climb to nothing" do
    order = calculate(people: ladder(4), contest_results: contest(winner: 3, loser: 1))

    assert_equal [ 2, 1, 3, 4 ], order, "expected the demotion to win the contested slot"
  end

  test "adjacent people exchange places when the lower wins" do
    order = calculate(people: ladder(4), contest_results: contest(winner: 3, loser: 2))

    assert_equal [ 1, 3, 2, 4 ], order, "expected an exchange when the gap is one"
  end

  test "contests apply in played order, not the order they were handed over" do
    late = contest(winner: 4, loser: 1, at: "2026-03-05 18:00", contest_id: 2)
    early = contest(winner: 3, loser: 1, at: "2026-03-03 18:00", contest_id: 1)

    assert_equal calculate(people: ladder(4), contest_results: late + early),
      calculate(people: ladder(4), contest_results: early + late),
      "expected the same standings whichever order the results arrived in"
  end

  test "numbers the standings from one, contiguously" do
    standings = CalculateStandings.call(people: ladder(3), contest_results: [])

    assert_equal [ Standing.new(person_id: 1, position: 1),
                   Standing.new(person_id: 2, position: 2),
                   Standing.new(person_id: 3, position: 3) ], standings,
      "expected each person to be handed their position, not left to be counted off"
  end

  private
    def calculate(people:, contest_results: [])
      CalculateStandings.call(people: people, contest_results: contest_results).map(&:person_id)
    end

    def person(id, joined_on)
      Person.new(id: id, joined_on: Date.parse(joined_on))
    end

    def ladder(size)
      (1..size).map { |id| person(id, "2026-01-#{format("%02d", id)}") }
    end

    def contest(winner:, loser:, tie: false, at: "2026-03-03 18:00", contest_id: 1)
      record = Contest.new(id: contest_id, played_at: LocalZone.zone.parse(at))

      [
        ContestResult.new(contest: record, contest_id: contest_id, person_id: winner, place: 1),
        ContestResult.new(contest: record, contest_id: contest_id, person_id: loser, place: tie ? 1 : 2)
      ]
    end
end

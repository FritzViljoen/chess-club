require "test_helper"

class UpdateContestTest < ActiveSupport::TestCase
  test "recomputes every position that followed the corrected contest" do
    people = 4.times.map { |index| create_person("p#{index}@example.test", index) }
    contest = CreateContest.call(
      played_at: at("2026-03-03 18:00"), winner: people[3], loser: people[0], tie: false
    ).value

    UpdateContest.call(
      contest: contest, played_at: at("2026-03-03 18:00"),
      winner: people[0], loser: people[3], tie: false
    )

    assert_equal people.map(&:id), StandingsCache.order(:position).pluck(:person_id),
      "expected correcting the outcome to undo the movement it caused"
  end

  test "removing a contest undoes it" do
    people = 4.times.map { |index| create_person("p#{index}@example.test", index) }
    contest = CreateContest.call(
      played_at: at("2026-03-03 18:00"), winner: people[3], loser: people[0], tie: false
    ).value

    RemoveContest.call(contest: contest)

    assert_equal people.map(&:id), StandingsCache.order(:position).pluck(:person_id),
      "expected the standings to return to the seed once the log was empty"
  end

  # The point of the whole design: entry order must not reach the answer.
  test "the same contests entered in a different order give the same standings" do
    people = 4.times.map { |index| create_person("p#{index}@example.test", index) }
    record(people[3], people[0], "2026-03-03 18:00")
    record(people[2], people[1], "2026-03-05 18:00")
    forwards = StandingsCache.order(:position).pluck(:person_id)

    Contest.destroy_all
    RecalculateStandings.call
    record(people[2], people[1], "2026-03-05 18:00")
    record(people[3], people[0], "2026-03-03 18:00")

    assert_equal forwards, StandingsCache.order(:position).pluck(:person_id),
      "expected the later contest entered first to reach the same answer"
  end

  private
    def record(winner, loser, literal)
      CreateContest.call(played_at: at(literal), winner: winner, loser: loser, tie: false)
    end

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

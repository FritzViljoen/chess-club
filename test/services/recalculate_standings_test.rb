require "test_helper"

class RecalculateStandingsTest < ActiveSupport::TestCase
  test "a new person starts last" do
    first = create_person(email: "a@example.test", joined_on: Date.new(2026, 1, 1))

    second = create_person(email: "b@example.test", joined_on: Date.new(2026, 1, 2))

    assert_equal [ first.id, second.id ], order, "expected a new person to start last"
  end

  test "a back-dated joiner is seeded ahead of people who joined later" do
    late = create_person(email: "b@example.test", joined_on: Date.new(2026, 1, 31))

    early = create_person(email: "a@example.test", joined_on: Date.new(2026, 1, 1))

    assert_equal [ early.id, late.id ], order,
      "expected join date to decide the order, not the order of entry"
  end

  test "a refused write leaves the standings alone" do
    create_person(email: "a@example.test", joined_on: Date.new(2026, 1, 1))

    CreatePerson.call(
      name: "Ann", surname: "Baker", email: "a@example.test",
      born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 2, 1)
    )

    assert_equal 1, StandingsCache.count, "expected a refusal to change nothing"
  end

  test "recording a contest moves the standings" do
    people = ladder(4)

    record(people[3], people[0], "2026-03-03 18:00")

    assert_equal [ people[1], people[0], people[3], people[2] ].map(&:id), order,
      "expected the loser to drop one and the winner to climb half the gap"
  end

  test "correcting a contest undoes the movement it caused" do
    people = ladder(4)
    contest = record(people[3], people[0], "2026-03-03 18:00")

    UpdateContest.call(contest: contest, played_at: local_time("2026-03-03 18:00"),
      winner: people[0], loser: people[3], tie: false)

    assert_equal people.map(&:id), order,
      "expected the standings to be worked out again from the corrected log"
  end

  test "removing a contest undoes it" do
    people = ladder(4)

    RemoveContest.call(contest: record(people[3], people[0], "2026-03-03 18:00"))

    assert_equal people.map(&:id), order,
      "expected the standings to return to the seed once the log was empty"
  end

  test "removing a person closes the gap they left" do
    people = ladder(3)

    RemovePerson.call(person: people[0])

    assert_equal [ [ people[1].id, 1 ], [ people[2].id, 2 ] ],
      StandingsCache.order(:position).pluck(:person_id, :position),
      "expected the positions to stay contiguous from 1"
  end

  test "the same contests entered in a different order give the same standings" do
    people = ladder(4)
    record(people[3], people[0], "2026-03-03 18:00")
    record(people[2], people[1], "2026-03-05 18:00")
    forwards = order

    ContestResult.delete_all
    Contest.delete_all
    RecalculateStandings.call
    record(people[2], people[1], "2026-03-05 18:00")
    record(people[3], people[0], "2026-03-03 18:00")

    assert_equal forwards, order,
      "expected the later contest entered first to reach the same answer"
  end

  test "two contests in the same minute give one board, whichever was entered first" do
    people = ladder(6)
    record(people[5], people[0], "2026-03-03 18:00")
    record(people[4], people[1], "2026-03-03 18:00")
    forwards = order

    ContestResult.delete_all
    Contest.delete_all
    RecalculateStandings.call
    record(people[4], people[1], "2026-03-03 18:00")
    record(people[5], people[0], "2026-03-03 18:00")

    assert_equal forwards, order,
      "expected a shared moment to be broken by who played, not by which was typed first"
  end

  private
    def order
      StandingsCache.order(:position).pluck(:person_id)
    end

    def ladder(size)
      size.times.map { |index| create_person(email: "p#{index}@example.test", joined_on: Date.new(2026, 1, 1) + index) }
    end

    def record(winner, loser, literal)
      CreateContest.call(played_at: local_time(literal), winner: winner, loser: loser, tie: false)
    end

    def create_person(email:, name: "Ann", surname: "Baker",
                      born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 5))
      CreatePerson.call(
        name: name, surname: surname, email: email,
        born_on: born_on, joined_on: joined_on
      )
    end

    def local_time(literal)
      LocalZone.zone.parse(literal)
    end
end

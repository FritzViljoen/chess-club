require "test_helper"

class UpdateContestTest < ActiveSupport::TestCase
  test "replaces the outcome" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")
    contest = record(bob, ann)

    UpdateContest.call(contest: contest, played_at: local_time("2026-03-03 18:00"),
      winner: ann, loser: bob, tie: false)

    assert_equal [ [ ann.id, 1 ], [ bob.id, 2 ] ],
      contest.reload.contest_results.sort_by(&:place).map { |r| [ r.person_id, r.place ] },
      "expected the corrected outcome to replace the old one"
    assert_equal 2, ContestResult.count, "expected the old results to go, not to pile up"
  end

  test "moves when it was played" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")
    contest = record(bob, ann)

    UpdateContest.call(contest: contest, played_at: local_time("2026-03-09 09:15"),
      winner: bob, loser: ann, tie: false)

    assert_equal "2026-03-09 09:15", contest.reload.played_at.in_time_zone(LocalZone::NAME).strftime("%Y-%m-%d %H:%M"),
      "expected the contest to be moved to the corrected moment"
  end

  test "removing a contest takes its results with it" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")

    RemoveContest.call(contest: record(bob, ann))

    assert_equal 0, Contest.count, "expected the contest to be gone"
    assert_equal 0, ContestResult.count, "expected its results to go with it"
  end

  test "a refused edit leaves the contest exactly as it was" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")
    contest = record(bob, ann)

    result = UpdateContest.call(contest: contest, played_at: local_time("2026-03-03 18:00"),
      winner: ann, loser: ann, tie: false)

    assert_not result.errors.none?, "expected one person against themselves to be refused"
    assert_equal 2, contest.reload.contest_results.count,
      "expected the refused edit to put the original results back"
    assert_equal [ bob.id, ann.id ], contest.in_place_order.map(&:person_id),
      "expected the original outcome to survive untouched"
  end

  private
    def record(winner, loser)
      CreateContest.call(played_at: local_time("2026-03-03 18:00"),
        winner: winner, loser: loser, tie: false)
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

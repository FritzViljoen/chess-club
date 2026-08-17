require "test_helper"

class RemovePersonTest < ActiveSupport::TestCase
  test "removes the person, their results and the contests they were in" do
    ann = create("a@example.test")
    bob = create("b@example.test")
    record_contest(ann, bob)

    RemovePerson.call(person: ann)

    assert_equal 0, Person.where(id: ann.id).count, "expected the person to be gone"
    assert_equal 0, Contest.count, "expected a contest they played in to be gone"
    assert_equal 0, ContestResult.count, "expected the opponent's result to go with it"
  end

  test "closes the gap they left in the standings" do
    ann = create("a@example.test")
    bob = create("b@example.test")

    RemovePerson.call(person: ann)

    assert_equal [ [ bob.id, 1 ] ], StandingsCache.order(:position).pluck(:person_id, :position),
      "expected the remaining person to be position 1"
  end

  private
    def create(email)
      CreatePerson.call(
        name: "Ann", surname: "Baker", email: email,
        born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 5)
      ).value
    end

    def record_contest(winner, loser)
      contest = Contest.new(played_at: LocalZone.zone.parse("2026-03-03 18:00"))
      contest.contest_results.build(person: winner, place: 1)
      contest.contest_results.build(person: loser, place: 2)
      contest.save!
      contest
    end
end

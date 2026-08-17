require "test_helper"

class RemovePersonTest < ActiveSupport::TestCase
  test "removes the person, their results and the contests they were in" do
    ann = create_person(email: "a@example.test")
    bob = create_person(email: "b@example.test")
    record_contest(ann, bob)

    RemovePerson.call(person: ann)

    assert_equal 0, Person.where(id: ann.id).count, "expected the person to be gone"
    assert_equal 0, Contest.count, "expected a contest they played in to be gone"
    assert_equal 0, ContestResult.count, "expected the opponent's result to go with it"
  end

  test "leaves people they never played alone" do
    ann = create_person(email: "a@example.test")
    bob = create_person(email: "b@example.test")

    RemovePerson.call(person: ann)

    assert_equal [ bob.id ], Person.pluck(:id), "expected the other person to survive"
  end

  private
    def record_contest(winner, loser)
      CreateContest.call(
        played_at: LocalZone.zone.parse("2026-03-03 18:00"),
        winner: winner, loser: loser, tie: false
      )
    end

    def create_person(email:, name: "Ann", surname: "Baker",
                      born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 5))
      CreatePerson.call(
        name: name, surname: surname, email: email,
        born_on: born_on, joined_on: joined_on
      )
    end
end

require "test_helper"

class CreateContestTest < ActiveSupport::TestCase
  test "stores the contest and both results" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")

    result = CreateContest.call(played_at: local_time("2026-03-03 18:00"), winner: bob, loser: ann, tie: false)

    assert result.errors.none?, "expected a contest between two people to be stored"
    assert_equal [ [ bob.id, 1 ], [ ann.id, 2 ] ],
      result.contest_results.sort_by(&:place).map { |r| [ r.person_id, r.place ] },
      "expected the winner on place 1 and the loser on place 2"
  end

  test "gives both people first place on a tie" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")

    result = CreateContest.call(played_at: local_time("2026-03-03 18:00"), winner: ann, loser: bob, tie: true)

    assert_equal [ 1, 1 ], result.contest_results.map(&:place),
      "expected a tie to make which person is named winner stop mattering"
  end

  test "refuses one person against themselves" do
    person = create_person(email: "a@example.test")

    result = CreateContest.call(played_at: local_time("2026-03-03 18:00"), winner: person, loser: person, tie: false)

    assert_not result.errors.none?, "expected a person against themselves to be refused"
    assert result.errors.any?, "expected the record to carry why it was refused"
    assert_equal 0, Contest.count, "expected a refusal to store nothing"
  end

  test "refuses a contest played before somebody joined" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")

    result = CreateContest.call(played_at: local_time("2025-12-31 18:00"), winner: bob, loser: ann, tie: false)

    assert_not result.errors.none?, "expected a contest predating a participant to be refused"
    assert result.errors.any?, "expected the record to carry why it was refused"
  end

  private
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

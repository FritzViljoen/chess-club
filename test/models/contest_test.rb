require "test_helper"

class ContestTest < ActiveSupport::TestCase
  test "is valid with two results and a winner" do
    assert contest.valid?, "expected two results with a first place to be valid"
  end

  test "is valid with two results that tie" do
    assert contest(places: [ 1, 1 ]).valid?, "expected a tie to be valid"
  end

  test "refuses a single result" do
    subject = contest(places: [ 1 ])

    assert_not subject.valid?, "expected one result to be refused"
    assert_includes subject.errors[:contest_results], "must be exactly two"
  end

  test "refuses three results" do
    subject = contest(places: [ 1, 2, 3 ])

    assert_not subject.valid?, "expected three results to be refused"
    assert_includes subject.errors[:contest_results], "must be exactly two"
  end

  test "refuses two results with the same person" do
    person = create_person(email: "ann@example.test")
    subject = Contest.new(played_at: Time.utc(2026, 3, 3, 18, 0))
    subject.contest_results.build(person: person, place: 1)
    subject.contest_results.build(person: person, place: 2)

    assert_not subject.valid?, "expected one person twice to be refused"
    assert_includes subject.errors[:contest_results], "must name two different people"
  end

  test "refuses results where nobody finished first" do
    subject = contest(places: [ 2, 3 ])

    assert_not subject.valid?, "expected a set with no first place to be refused"
    assert_includes subject.errors[:contest_results], "must include a first place"
  end

  test "refuses a contest played before somebody joined" do
    subject = contest
    subject.played_at = LocalZone.zone.parse("2025-12-31 18:00")

    assert_not subject.valid?, "expected a contest predating a participant to be refused"
    assert_includes subject.errors[:played_at], "cannot be before somebody joined"
  end

  test "accepts a contest played on the day somebody joined" do
    subject = contest
    subject.played_at = LocalZone.zone.parse("2026-01-05 09:00")

    assert subject.valid?, "expected the join date itself to be early enough"
  end

  private
    def contest(places: [ 1, 2 ])
      subject = Contest.new(played_at: Time.utc(2026, 3, 3, 18, 0))

      places.each_with_index do |place, index|
        subject.contest_results.build(person: create_person(email: "p#{index}@example.test"), place: place)
      end

      subject
    end

    def create_person(email:, name: "Ann", surname: "Baker",
                      born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 5))
      CreatePerson.call(
        name: name, surname: surname, email: email,
        born_on: born_on, joined_on: joined_on
      )
    end
end

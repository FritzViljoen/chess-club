require "test_helper"

class ReadContestsTest < ActiveSupport::TestCase
  test "newest first by default" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")
    record(ann, bob, "2026-03-03 18:00")
    late = record(bob, ann, "2026-03-09 18:00")

    assert_equal late.id, ReadContests.call(sort: "newest", page: 1, query: "").rows.first.id,
      "expected the most recent match at the top"
  end

  test "oldest first when asked" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")
    early = record(ann, bob, "2026-03-03 18:00")
    record(bob, ann, "2026-03-09 18:00")

    assert_equal early.id, ReadContests.call(sort: "oldest", page: 1, query: "").rows.first.id
  end

  test "pages at ten" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")
    11.times { |index| record(ann, bob, "2026-03-#{format("%02d", index + 3)} 18:00") }

    page = ReadContests.call(sort: "newest", page: 2, query: "")

    assert_equal 1, page.rows.size, "expected the eleventh match alone on page two"
    assert_equal 11, page.total
  end

  test "searches by either participant" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")
    cy = create_person(email: "cy@example.test", name: "Cy")
    match = record(ann, bob, "2026-03-03 18:00")
    record(cy, ann, "2026-03-09 18:00")

    assert_equal [ match.id ], read(query: "bob").rows.map(&:id), "expected a match found by its loser"
  end

  test "a term matching both participants returns the contest once" do
    ann = create_person(email: "ann.baker@example.test", name: "Ann")
    bob = create_person(email: "bob.baker@example.test", name: "Bob")
    record(ann, bob, "2026-03-03 18:00")

    page = read(query: "Baker")

    assert_equal 1, page.rows.size, "expected one row, not one per participant"
    assert_equal 1, page.total, "expected the count to agree with the rows"
  end

  test "a searched contest still carries both participants" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")
    record(ann, bob, "2026-03-03 18:00")

    contest = read(query: "ann").rows.first

    assert_equal 2, contest.contest_results.size,
      "expected the match found by one player to still know about the other"
    assert_equal [ ann.id, bob.id ].sort, contest.contest_results.map(&:person_id).sort
  end

  test "a search that matches nothing is an empty page" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")
    record(ann, bob, "2026-03-03 18:00")

    assert_empty read(query: "zzz").rows
    assert_equal 0, read(query: "zzz").total
  end

  test "refuses a sort it does not know" do
    assert_raises(ArgumentError, "expected an unknown sort to be a caller defect") do
      ReadContests.call(sort: "played_at DESC; --", page: 1, query: "")
    end
  end

  private
    def read(sort: "newest", page: 1, query: "")
      ReadContests.call(sort: sort, page: page, query: query)
    end

    def record(winner, loser, at)
      CreateContest.call(played_at: LocalZone.zone.parse(at),
        winner: winner, loser: loser, tie: false)
    end

    def create_person(email:, name: "Ann", surname: "Baker",
                      born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 5))
      CreatePerson.call(
        name: name, surname: surname, email: email,
        born_on: born_on, joined_on: joined_on
      )
    end
end

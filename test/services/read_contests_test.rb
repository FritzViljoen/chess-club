require "test_helper"

class ReadContestsTest < ActiveSupport::TestCase
  test "newest first by default" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")
    record(ann, bob, "2026-03-03 18:00")
    late = record(bob, ann, "2026-03-09 18:00")

    assert_equal late.id, read.rows.first.id,
      "expected the most recent match at the top"
  end

  test "oldest first when asked" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")
    early = record(ann, bob, "2026-03-03 18:00")
    record(bob, ann, "2026-03-09 18:00")

    assert_equal early.id, read(direction: "asc").rows.first.id
  end

  test "pages at ten" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")
    11.times { |index| record(ann, bob, "2026-03-#{format("%02d", index + 3)} 18:00") }

    page = read(page: 2)

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

  test "refuses a sort or a direction it does not know" do
    injected = assert_raises(ArgumentError) do
      ReadContests.call(sort: "played_at DESC; --", direction: "asc", page: 1, query: "")
    end
    assert_match(/expected one of/, injected.message, "expected the sort allowlist, not a missing keyword")

    assert_raises(ArgumentError) do
      ReadContests.call(sort: "played", direction: "played_at DESC; --", page: 1, query: "")
    end
  end

  test "a match removed mid-read costs its row, not the page" do
    ann = create_person(email: "ann@example.test", name: "Ann", surname: "Abrahams")
    bob = create_person(email: "bob@example.test", name: "Bob", surname: "Mokoena")
    doomed = record(ann, bob, "2026-03-03 18:00")
    record(bob, ann, "2026-03-04 18:00")

    reader = ReadContests.new(sort: "played", direction: "desc", page: 1, query: "")
    reader.define_singleton_method(:ordered_ids) do |_number|
      Contest.order(played_at: :desc).pluck(:id).tap { RemoveContest.call(contest: doomed) }
    end

    assert_equal 1, reader.call.rows.size, "expected the surviving match, not a KeyError"
  end

  test "sorts by the name a row leads with, and turns around" do
    ann = create_person(email: "ann@example.test", name: "Ann", surname: "Abrahams")
    bob = create_person(email: "bob@example.test", name: "Bob", surname: "Mokoena")
    cy = create_person(email: "cy@example.test", name: "Cy", surname: "Zulu")
    record(cy, ann, "2026-03-03 18:00")
    record(ann, bob, "2026-03-04 18:00")

    forwards = read(sort: "result", direction: "asc").rows
    backwards = read(sort: "result", direction: "desc").rows

    assert_equal %w[ Abrahams Zulu ], forwards.map { |contest| contest.in_place_order.first.person.surname }
    assert_equal forwards.map(&:id).reverse, backwards.map(&:id)
  end

  test "a draw leads with the first of the two by name, and sorts there" do
    ann = create_person(email: "ann@example.test", name: "Ann", surname: "Abrahams")
    zed = create_person(email: "zed@example.test", name: "Zed", surname: "Zulu")
    CreateContest.call(played_at: LocalZone.zone.parse("2026-03-03 18:00"),
      winner: zed, loser: ann, tie: true)

    contest = read(sort: "result", direction: "asc").rows.sole

    assert_equal "Abrahams", contest.in_place_order.first.person.surname,
      "expected a draw to lead with the earlier name, not the one entered first"
  end

  test "both participants arrive with every row, whatever the sort" do
    ann = create_person(email: "ann@example.test", name: "Ann", surname: "Abrahams")
    bob = create_person(email: "bob@example.test", name: "Bob", surname: "Mokoena")
    record(ann, bob, "2026-03-03 18:00")

    ReadContests::SORTS.each do |sort|
      contest = read(sort: sort).rows.sole

      assert_equal 2, contest.contest_results.size, "expected #{sort} to keep both participants"
    end
  end

  private
    def read(sort: "played", direction: nil, page: 1, query: "")
      ReadContests.call(sort: sort, direction: direction || ReadContests::NATURAL.fetch(sort), page: page, query: query)
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

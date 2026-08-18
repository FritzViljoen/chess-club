require "test_helper"

class ReadPeopleTest < ActiveSupport::TestCase
  test "sorts by surname then first name" do
    create("Zaan", "Abrahams")
    create("Ana", "Zulu")

    assert_equal [ "Abrahams", "Zulu" ], read.rows.map(&:surname),
      "expected the default sort to be alphabetical by surname"
  end

  test "sorts by when they joined" do
    late = create("Late", "Joiner", joined_on: Date.new(2026, 6, 1))
    early = create("Early", "Bird", joined_on: Date.new(2026, 1, 1))

    assert_equal [ early.id, late.id ], read(sort: "joined").rows.map(&:id),
      "expected the earliest joiner first"
  end

  test "sorts by games played, most first" do
    busy = create("Busy", "One")
    quiet = create("Quiet", "Two")
    CreateContest.call(played_at: LocalZone.zone.parse("2026-07-01 18:00"),
      winner: busy, loser: quiet, tie: false)
    idle = create("Idle", "Three")

    assert_equal idle.id, read(sort: "played").rows.last.id,
      "expected the person who has played nothing to come last"
  end

  test "pages at ten" do
    12.times { |index| create("P#{index}", "Surname#{format("%02d", index)}") }

    first = read
    second = read(page: 2)

    assert_equal 10, first.rows.size, "expected a full first page"
    assert_equal 2, second.rows.size, "expected the remainder on the second"
    assert_equal 12, first.total
  end

  test "a page past the end lands on the last one" do
    3.times { |index| create("P#{index}", "S#{index}") }

    assert_equal 1, read(page: 99).number, "expected an out-of-range page to be clamped"
  end

  test "a page below one lands on the first" do
    3.times { |index| create("P#{index}", "S#{index}") }

    assert_equal 1, read(page: 0).number
  end

  test "searches across first name, surname and email" do
    create("Nomsa", "Dlamini")
    create("Pieter", "van Wyk")

    assert_equal [ "Dlamini" ], read(query: "noms").rows.map(&:surname), "expected a first-name match"
    assert_equal [ "van Wyk" ], read(query: "wyk").rows.map(&:surname), "expected a surname match"
    assert_equal [ "Dlamini" ], read(query: "nomsa.dlamini@").rows.map(&:surname), "expected an email match"
  end

  test "a search that matches nothing is an empty page, not a refusal" do
    create("Nomsa", "Dlamini")

    page = read(query: "zzz")

    assert_empty page.rows
    assert_equal 0, page.total
    assert_equal 1, page.number, "expected an empty result to still be page one"
  end

  test "a wildcard in the search is a literal, not a pattern" do
    create("Nomsa", "Dlamini")
    match = create("Odd%Name", "Percent")

    assert_equal [ match.id ], read(query: "%").rows.map(&:id),
      "expected % to match only the person whose name contains it"
  end

  test "an underscore in the search is a literal too" do
    create("Nomsa", "Dlamini")

    assert_empty read(query: "_").rows, "expected _ to match a literal underscore, not any character"
  end

  test "the total counts the search, not the whole list" do
    12.times { |index| create("P#{index}", "Surname#{format("%02d", index)}") }
    create("Findme", "Unique")

    assert_equal 1, read(query: "findme").total, "expected the count to follow the search"
  end

  test "search survives sorting" do
    create("Zaan", "Abrahams")
    create("Zaan", "Zulu")

    assert_equal [ "Abrahams", "Zulu" ], read(query: "zaan", sort: "joined").rows.map(&:surname),
      "expected both matches to survive a different sort"
  end

  test "refuses a sort or a direction it does not know" do
    injected = assert_raises(ArgumentError) do
      ReadPeople.call(sort: "; DROP TABLE people", direction: "asc", page: 1, query: "")
    end
    assert_match(/expected one of/, injected.message, "expected the sort allowlist, not a missing keyword")

    assert_raises(ArgumentError) do
      ReadPeople.call(sort: "name", direction: "asc; DROP TABLE people", page: 1, query: "")
    end
  end

  test "carries each player's rank from the cache, in one query" do
    late = create("Late", "Joiner", joined_on: Date.new(2026, 6, 1))
    early = create("Early", "Bird", joined_on: Date.new(2026, 1, 1))

    rows = nil
    queries = count_queries { rows = read.rows }

    assert_equal({ early.id => 1, late.id => 2 }, rows.to_h { |person| [ person.id, person.position ] })
    assert_equal 2, queries, "expected the count and the page, and no query per row"
  end

  test "a player the cache does not hold has no rank rather than no row" do
    person = create("Un", "Ranked")
    StandingsCache.delete_all

    assert_nil read.rows.sole.position, "expected the left join to keep the row"
  end

  test "a column with distinct values reverses when the direction is turned around" do
    create("Ana", "Abrahams", joined_on: Date.new(2026, 1, 1))
    create("Bea", "Mokoena", joined_on: Date.new(2026, 2, 1))
    create("Cy", "Zulu", joined_on: Date.new(2026, 3, 1))

    %w[ rank name email joined ].each do |sort|
      forwards = read(sort: sort, direction: "asc").rows.map(&:id)
      backwards = read(sort: sort, direction: "desc").rows.map(&:id)

      assert_equal forwards.reverse, backwards, "expected #{sort} to reverse"
    end
  end

  # Every contest counts for both players, so no set of people can have all
  # different totals — someone at zero and someone who has played everybody
  # cannot both exist. The column turns around; the tie behind it does not.
  test "turning the count around puts the busiest first, ties still by surname" do
    busy = create("Ana", "Abrahams")
    quiet = create("Bea", "Mokoena")
    create("Cy", "Zulu")
    CreateContest.call(played_at: LocalZone.zone.parse("2026-07-01 18:00"),
      winner: busy, loser: quiet, tie: false)

    assert_equal %w[ Zulu Abrahams Mokoena ], read(sort: "played", direction: "asc").rows.map(&:surname)
    assert_equal %w[ Abrahams Mokoena Zulu ], read(sort: "played", direction: "desc").rows.map(&:surname)
  end

  test "a tie holds its order, so turning the column around does not shuffle it" do
    create("Ana", "Abrahams")
    create("Zaan", "Zulu")

    forwards = read(sort: "played", direction: "asc").rows.map(&:surname)
    backwards = read(sort: "played", direction: "desc").rows.map(&:surname)

    assert_equal %w[ Abrahams Zulu ], forwards
    assert_equal forwards, backwards, "expected the surname tiebreak to read forwards either way"
  end

  test "a direction outside the two is the caller's defect" do
    assert_raises(ArgumentError) { read(direction: "sideways") }
  end

  private
    def count_queries
      queries = 0
      counter = ->(*, payload) { queries += 1 unless payload[:name].in?([ "SCHEMA", "TRANSACTION" ]) }

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
      queries
    end

    def read(sort: "name", direction: nil, page: 1, query: "")
      ReadPeople.call(sort: sort, direction: direction || ReadPeople::NATURAL.fetch(sort), page: page, query: query)
    end

    def create(name, surname, joined_on: Date.new(2026, 1, 5))
      CreatePerson.call(
        name: name, surname: surname, email: "#{name}.#{surname}@example.test".downcase,
        born_on: Date.new(1990, 4, 2), joined_on: joined_on
      )
    end
end

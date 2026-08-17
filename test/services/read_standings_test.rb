require "test_helper"

class ReadStandingsTest < ActiveSupport::TestCase
  test "answers with the rows in rank order" do
    first = create_person(email: "a@example.test", joined_on: Date.new(2026, 1, 1))
    second = create_person(email: "b@example.test", joined_on: Date.new(2026, 1, 2))

    assert_equal [ first.id, second.id ], read.rows.map(&:person_id),
      "expected rank 1 to come back first"
  end

  test "answers with an empty page rather than a refusal when nobody has joined" do
    result = ReadStandings.call(page: 1)

    assert_empty result.rows
    assert_equal 1, result.pages, "expected an empty board to still be one page"
  end

  test "pages at ten, keeping rank order across the break" do
    12.times { |index| create_person(email: "p#{index}@example.test", joined_on: Date.new(2026, 1, 1) + index) }

    assert_equal (1..10).to_a, read.rows.map(&:position)
    assert_equal [ 11, 12 ], read(page: 2).rows.map(&:position),
      "expected the second page to carry on where the first stopped"
  end

  private
    def read(page: 1)
      ReadStandings.call(page: page)
    end

    def create_person(email:, name: "Ann", surname: "Baker",
                      born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 5))
      CreatePerson.call(
        name: name, surname: surname, email: email,
        born_on: born_on, joined_on: joined_on
      )
    end
end

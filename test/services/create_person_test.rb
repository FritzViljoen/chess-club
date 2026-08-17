require "test_helper"

class CreatePersonTest < ActiveSupport::TestCase
  test "adds the person to the end of the standings" do
    first = create("a@example.test", "2026-01-01").value

    second = create("b@example.test", "2026-02-01").value

    assert_equal [ first.id, second.id ], StandingsCache.order(:position).pluck(:person_id),
      "expected a new person to start last"
  end

  test "refuses a duplicate email without touching the standings" do
    create("a@example.test", "2026-01-01")

    result = create("a@example.test", "2026-02-01")

    assert_not result.success?, "expected a repeated email to be refused"
    assert_equal :invalid, result.error
    assert_equal 1, StandingsCache.count, "expected a refusal to leave the standings alone"
  end

  test "seeds a back-dated joiner ahead of people who joined later" do
    late = create("b@example.test", "2026-02-01").value

    early = create("a@example.test", "2026-01-01").value

    assert_equal [ early.id, late.id ], StandingsCache.order(:position).pluck(:person_id),
      "expected join date to decide the order, not the order of entry"
  end

  private
    def create(email, joined_on)
      CreatePerson.call(
        name: "Ann", surname: "Baker", email: email,
        born_on: Date.new(1990, 4, 2), joined_on: Date.parse(joined_on)
      )
    end
end

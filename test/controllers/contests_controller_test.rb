require "test_helper"

class ContestsControllerTest < ActionDispatch::IntegrationTest
  test "records a contest" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")

    post contests_path, params: {
      played_at: "2026-03-03 18:00", tie: "0", winner_id: bob.id, loser_id: ann.id
    }

    assert_redirected_to contests_path
    assert_equal 1, Contest.count, "expected the contest to be stored"
    assert_equal [ [ bob.id, 1 ], [ ann.id, 2 ] ],
      ContestResult.order(:place).pluck(:person_id, :place),
      "expected the winner on place 1"
  end

  test "records a tie" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")

    post contests_path, params: {
      played_at: "2026-03-03 18:00", tie: "1", winner_id: ann.id, loser_id: bob.id
    }

    assert_equal [ 1, 1 ], ContestResult.order(:id).pluck(:place),
      "expected a tie to give both people first place"
  end

  test "bounces a time it cannot read" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")

    post contests_path, params: {
      played_at: "half past nonsense", tie: "0", winner_id: bob.id, loser_id: ann.id
    }

    assert_response :redirect
    assert_equal 0, Contest.count, "expected an unreadable time to store nothing"
  end

  test "lists the contests" do
    ann = create_person(email: "ann@example.test", name: "Ann")
    bob = create_person(email: "bob@example.test", name: "Bob")
    CreateContest.call(played_at: LocalZone.zone.parse("2026-03-03 18:00"),
      winner: bob, loser: ann, tie: false)

    get contests_path

    assert_response :success
    assert_select "td", text: /Bob Baker beat Ann Baker/
  end

  private
    def create_person(email:, name: "Ann", surname: "Baker",
                      born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 5))
      CreatePerson.call(
        name: name, surname: surname, email: email,
        born_on: born_on, joined_on: joined_on
      )
    end
end

require "test_helper"

class StandingsControllerTest < ActionDispatch::IntegrationTest
  test "shows every person with their position" do
    CreatePerson.call(
      name: "Ann", surname: "Baker", email: "ann@example.test",
      born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 1)
    )

    get standings_path

    assert_response :success
    assert_select "td.position", text: "1"
    assert_select "td.name", text: /Ann Baker/
  end

  test "says so when nobody has joined" do
    get standings_path

    assert_response :success
    assert_select "p.empty"
  end

  test "is the root page" do
    get root_path

    assert_response :success
  end
end

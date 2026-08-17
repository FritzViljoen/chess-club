require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  test "creates a person and puts them in the standings" do
    post people_path, params: attributes

    assert_redirected_to people_path
    assert_equal 1, Person.count, "expected the person to be stored"
    assert_equal 1, StandingsCache.count, "expected the standings to be recomputed"
  end

  test "re-renders the form when the person is refused" do
    post people_path, params: attributes(name: "")

    assert_response :unprocessable_entity
    assert_equal 0, Person.count, "expected nothing to be stored"
  end

  test "bounces a date it cannot read" do
    post people_path, params: attributes(joined_on: "not a date")

    assert_response :redirect
    assert_equal 0, Person.count, "expected an unreadable date to store nothing"
  end

  test "removes a person" do
    post people_path, params: attributes

    delete person_path(Person.first)

    assert_redirected_to people_path
    assert_equal 0, Person.count, "expected the person to be gone"
    assert_equal 0, StandingsCache.count, "expected the standings to be recomputed without them"
  end

  test "lists the people" do
    post people_path, params: attributes

    get people_path

    assert_response :success
    assert_select "td", text: "Ann Baker"
  end

  private
    # The dates post at the top level, where the parsers look; the rest is nested
    # under `person`.
    def attributes(**overrides)
      submitted = {
        name: "Ann", surname: "Baker", email: "ann@example.test",
        born_on: "1990-04-02", joined_on: "2026-01-05"
      }.merge(overrides)

      {
        person: submitted.slice(:name, :surname, :email),
        born_on: submitted[:born_on],
        joined_on: submitted[:joined_on]
      }
    end
end

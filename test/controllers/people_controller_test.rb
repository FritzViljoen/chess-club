require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  test "creates a person" do
    post people_path, params: attributes

    assert_redirected_to people_path
    assert_equal 1, Person.count, "expected the person to be stored"
  end

  test "re-renders the form when the person is refused" do
    post people_path, params: attributes(name: "")

    assert_response :unprocessable_entity
    assert_equal 0, Person.count, "expected nothing to be stored"
  end

  test "an array where a name was expected is not stored as one" do
    post people_path, params: attributes(name: [ "Ann" ])

    assert_response :unprocessable_entity
    assert_equal 0, Person.count, "expected a blank name to be refused, not '[\"Ann\"]' stored"
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
  end

  test "searches the list" do
    post people_path, params: attributes
    post people_path, params: attributes(name: "Zaan", surname: "Zulu", email: "z@example.test")

    get people_path, params: { search: "zulu" }

    assert_select "td.who", count: 1
    assert_select "td.who", text: /Zaan Zulu/
  end

  test "a search term over the limit is bounced, not answered with everyone" do
    post people_path, params: attributes

    get people_path, params: { search: "x" * 201 }

    assert_redirected_to root_path
    assert_match(/valid search/, flash[:alert])
    assert_equal 1, Person.count, "expected the refusal to change nothing"
  end

  test "an array where a search term was expected searches for nothing" do
    post people_path, params: attributes

    get people_path, params: { "search" => [ "Baker" ] }

    assert_response :success
    assert_select "td.who", count: 1, text: /Ann Baker/
  end

  test "an id with rubbish appended does not quietly serve somebody" do
    post people_path, params: attributes

    get person_path("#{Person.first.id}abc")

    assert_response :redirect
  end

  test "a stale person id is not found rather than a 500" do
    get person_path(987_654)

    assert_response :not_found
  end

  test "lists the people" do
    post people_path, params: attributes

    get people_path

    assert_response :success
    assert_select "td", text: "Ann Baker"
  end

  test "the grid shows each player's current rank" do
    post people_path, params: attributes
    post people_path, params: attributes(name: "Zaan", surname: "Zulu", email: "z@example.test", joined_on: "2026-02-01")

    get people_path

    assert_select "td.position", text: "1"
    assert_select "td.position", text: "2"
  end

  test "the record shows the rank the board holds" do
    post people_path, params: attributes
    person = Person.sole

    get person_path(person)

    assert_select "dt", text: "Current rank"
    assert_select "dd", text: person.standing_cache.position.to_s
  end

  test "the sorted column offers the turn-around, not a dead heading" do
    post people_path, params: attributes

    get people_path, params: { sort: "name", dir: "asc" }

    # A link, not the dead <span> the sorted column used to render.
    assert_select "th a[href=?]", "/people?dir=desc&sort=name"
  end

  test "an unsorted column opens the way that column reads" do
    post people_path, params: attributes

    get people_path

    assert_select "th a[href=?]", "/people?dir=desc&sort=played"
    assert_select "th a[href=?]", "/people?dir=asc&sort=joined"
  end

  test "a search survives turning a column around" do
    post people_path, params: attributes

    get people_path, params: { search: "baker", sort: "name", dir: "asc" }

    assert_select "th a[href=?]", "/people?dir=desc&search=baker&sort=name"
  end

  private
    def attributes(**overrides)
      {
        name: "Ann", surname: "Baker", email: "ann@example.test",
        born_on: "1990-04-02", joined_on: "2026-01-05"
      }.merge(overrides)
    end
end

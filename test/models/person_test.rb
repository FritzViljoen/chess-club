require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "is valid with every attribute present" do
    assert person.valid?, "expected a fully populated person to be valid"
  end

  test "refuses a blank name" do
    subject = person(name: "")

    assert_not subject.valid?, "expected a blank name to be refused"
    assert_includes subject.errors[:name], "can't be blank"
  end

  test "refuses a duplicate email" do
    CreatePerson.call(
      name: "Ann", surname: "Baker", email: "ann@example.test",
      born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 5)
    )
    duplicate = person(email: "ann@example.test")

    assert_not duplicate.valid?, "expected a repeated email to be refused"
  end

  test "refuses a blank email" do
    subject = person(email: "")

    assert_not subject.valid?, "expected the identifier to be required"
    assert_includes subject.errors[:email], "can't be blank"
  end

  private
    def person(**overrides)
      Person.new(
        name: "Ann",
        surname: "Baker",
        email: "ann@example.test",
        born_on: Date.new(1990, 4, 2),
        joined_on: Date.new(2026, 1, 5),
        **overrides
      )
    end
end

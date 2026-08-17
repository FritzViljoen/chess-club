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
    person.save!
    duplicate = person(email: "ann@example.test")

    assert_not duplicate.valid?, "expected a repeated email to be refused"
  end

  test "allows more than one person without an email" do
    person(email: "").save!
    second = person(email: "")

    assert second.valid?, "expected a blank email to be exempt from uniqueness"
    assert second.save, "expected the partial index to let a second blank through"
  end

  test "starts with a blank email rather than nothing" do
    assert_equal "", Person.new.email, "expected the model to supply the starting value"
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

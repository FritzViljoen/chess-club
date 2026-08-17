require "test_helper"

class CreatePersonTest < ActiveSupport::TestCase
  test "stores the person" do
    result = create_result(email: "a@example.test")

    assert result.errors.none?, "expected a complete person to be stored"
    assert_equal "a@example.test", result.email
    assert_equal 1, Person.count
  end

  test "refuses a duplicate email" do
    create_result(email: "a@example.test")

    result = create_result(email: "a@example.test")

    assert_not result.errors.none?, "expected a repeated email to be refused"
    assert result.errors.any?, "expected the record to carry why it was refused"
    assert_equal 1, Person.count, "expected a refusal to store nothing"
  end

  test "refuses a blank email, which is how somebody is identified" do
    result = create_result(email: "")

    assert result.errors.any?, "expected the identifier to be required"
  end

  private
    def create_result(email:)
      CreatePerson.call(
        name: "Ann", surname: "Baker", email: email,
        born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 5)
      )
    end
end

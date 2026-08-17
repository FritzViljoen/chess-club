require "test_helper"

class ContestResultTest < ActiveSupport::TestCase
  test "refuses a place below one" do
    subject = ContestResult.new(place: 0)

    assert_not subject.valid?, "expected place 0 to be refused"
    assert_includes subject.errors[:place], "must be greater than 0"
  end
end

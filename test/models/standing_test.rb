require "test_helper"

class StandingTest < ActiveSupport::TestCase
  test "says who, and where" do
    standing = Standing.new(person_id: 7, position: 1)

    assert_equal 7, standing.person_id
    assert_equal 1, standing.position
  end

  test "two standings that say the same thing are the same standing" do
    assert_equal Standing.new(person_id: 7, position: 1), Standing.new(person_id: 7, position: 1)
  end

  test "standings differing in either half are not equal" do
    assert_not_equal Standing.new(person_id: 7, position: 1), Standing.new(person_id: 8, position: 1)
    assert_not_equal Standing.new(person_id: 7, position: 1), Standing.new(person_id: 7, position: 2)
  end

  test "a standing is not equal to something that merely answers alike" do
    lookalike = Struct.new(:person_id, :position).new(7, 1)

    assert_not_equal Standing.new(person_id: 7, position: 1), lookalike
  end

  test "equal standings hash alike" do
    first = Standing.new(person_id: 7, position: 1)
    second = Standing.new(person_id: 7, position: 1)

    assert_equal first.hash, second.hash
    assert_equal 1, [ first, second ].uniq.size
  end

  test "an id or a position that is not a number is the caller's defect" do
    assert_raises(ArgumentError) { Standing.new(person_id: "7", position: 1) }
    assert_raises(ArgumentError) { Standing.new(person_id: 7, position: "1") }
  end
end

require "test_helper"

class LadderTest < ActiveSupport::TestCase
  test "the person at the top is at position 1" do
    assert_equal 1, ladder.position_of(1)
    assert_equal 4, ladder.position_of(4)
  end

  test "moving somebody up shifts everybody between them down one" do
    moved = ladder.moved(4, to: 2)

    assert_equal [ 1, 4, 2, 3 ], moved.person_ids
    assert_equal 2, moved.position_of(4)
    assert_equal 3, moved.position_of(2), "expected 2 to be shifted down, not swapped away"
  end

  test "moving somebody down shifts everybody between them up one" do
    moved = ladder.moved(1, to: 3)

    assert_equal [ 2, 3, 1, 4 ], moved.person_ids
  end

  test "moving somebody one place is an exchange with their neighbour" do
    assert_equal [ 2, 1, 3, 4 ], ladder.moved(1, to: 2).person_ids
  end

  test "moving somebody where they already are changes nothing" do
    assert_equal [ 1, 2, 3, 4 ], ladder.moved(2, to: 2).person_ids
  end

  test "a move answers with a new ladder and leaves the old one alone" do
    original = ladder

    original.moved(1, to: 4)

    assert_equal [ 1, 2, 3, 4 ], original.person_ids, "expected the original to be untouched"
  end

  test "a second move finds its person wherever the first move left them" do
    once = ladder.moved(1, to: 2)
    twice = once.moved(4, to: 2)

    assert_equal [ 2, 4, 1, 3 ], twice.person_ids
  end

  test "a list of anything but ids is the caller's defect" do
    assert_raises(ArgumentError) { Ladder.new([ "1", "2" ]) }
  end

  private
    def ladder
      Ladder.new([ 1, 2, 3, 4 ])
    end
end

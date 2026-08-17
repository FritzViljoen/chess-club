require "test_helper"

class ListingTest < ActiveSupport::TestCase
  test "a link carries the sort and the search, plus what it changes" do
    assert_equal({ sort: "played", q: "nd", page: 3 }, listing.showing(page: 3))
  end

  test "what the link changes wins over what it carries" do
    assert_equal({ sort: "joined", q: "nd" }, listing.showing(sort: "joined"))
  end

  test "the search survives a re-sort" do
    assert_equal "nd", listing.showing(sort: "joined")[:q]
  end

  test "a blank sort or search is dropped, never sent as an empty parameter" do
    assert_equal({ page: 2 }, Listing.new(sort: "", query: "").showing(page: 2))
    assert_equal({ sort: "played", page: 2 }, Listing.new(sort: "played", query: "").showing(page: 2))
  end

  test "nothing else travels — a link is not a place to pass through what arrived" do
    assert_equal %i[ sort q page ], listing.showing(page: 2).keys
  end

  test "knows whether a search is on, for the control that clears it" do
    assert listing.searching?
    assert_not Listing.new(sort: "played", query: "").searching?
  end

  test "a sort or a search that is not text is the caller's defect" do
    assert_raises(ArgumentError) { Listing.new(sort: :played, query: "nd") }
    assert_raises(ArgumentError) { Listing.new(sort: "played", query: nil) }
  end

  private
    def listing
      Listing.new(sort: "played", query: "nd")
    end
end

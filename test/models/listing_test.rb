require "test_helper"

class ListingTest < ActiveSupport::TestCase
  test "a link carries the sort, its direction and the search, plus what it changes" do
    assert_equal({ sort: "played", dir: "desc", search: "nd", page: 3 }, listing.showing(page: 3))
  end

  test "what the link changes wins over what it carries" do
    assert_equal({ sort: "joined", dir: "desc", search: "nd" }, listing.showing(sort: "joined"))
  end

  test "the search survives a re-sort" do
    assert_equal "nd", listing.showing(sort: "joined")[:search]
  end

  test "the column already sorted is turned around" do
    assert_equal "played", listing.turned("played")[:sort]
    assert_equal "asc", listing.turned("played")[:dir]
  end

  test "another column opens the way that column reads, not the way this one does" do
    assert_equal({ sort: "name", dir: "asc", search: "nd" }, listing.turned("name"))
    assert_equal({ sort: "joined", dir: "asc", search: "nd" }, listing.turned("joined"))
  end

  test "turning a column drops the page, so a reorder starts at the first one" do
    assert_not_includes listing.turned("name").keys, :page
  end

  test "a listing with nothing to sort carries no sort and no direction" do
    assert_equal({ page: 2 }, Listing.unsorted.showing(page: 2))
  end

  test "a blank search is dropped, never sent as an empty parameter" do
    assert_equal({ sort: "played", dir: "desc", page: 2 }, unsearched.showing(page: 2))
  end

  test "nothing else travels — a link is not a place to pass through what arrived" do
    assert_equal %i[ sort dir search page ], listing.showing(page: 2).keys
  end

  test "knows whether a search is on, for the control that clears it" do
    assert listing.searching?
    assert_not unsearched.searching?
  end

  test "a direction outside the two is the caller's defect" do
    assert_raises(ArgumentError) { build(direction: "sideways") }
    assert_raises(ArgumentError) { build(direction: :asc) }
  end

  test "a sort or a search that is not text is the caller's defect" do
    assert_raises(ArgumentError) { build(sort: :played) }
    assert_raises(ArgumentError) { build(query: nil) }
  end

  test "a natural direction that is not text is the caller's defect" do
    assert_raises(ArgumentError) { build(natural: { "played" => :desc }) }
  end

  private
    NATURAL = { "played" => "desc", "name" => "asc", "joined" => "asc" }.freeze

    def build(sort: "played", direction: "desc", query: "nd", natural: NATURAL)
      Listing.new(sort: sort, direction: direction, query: query, natural: natural)
    end

    def listing
      build
    end

    def unsearched
      build(query: "")
    end
end

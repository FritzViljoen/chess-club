require "test_helper"

class PageTest < ActiveSupport::TestCase
  test "counts the pages a total needs" do
    assert_equal 4, page(total: 34).pages, "expected 34 rows at 10 a page to need 4"
    assert_equal 3, page(total: 30).pages, "expected an exact fit to need no extra page"
  end

  test "an empty list is still one page" do
    assert_equal 1, page(total: 0).pages, "expected no rows to be one empty page, not zero pages"
  end

  test "knows where it sits" do
    assert page(number: 1, total: 34).first?
    assert_not page(number: 1, total: 34).last?
    assert page(number: 4, total: 34).last?
  end

  test "counts the rows it is showing" do
    subject = page(number: 2, total: 34)

    assert_equal 11, subject.from, "expected the second page of ten to start at 11"
    assert_equal 20, subject.to
  end

  test "the last page stops at the total, not at a full page" do
    assert_equal 34, page(number: 4, total: 34).to, "expected the tail page to stop short"
  end

  test "an empty list shows nothing rather than row zero" do
    assert_equal 0, page(total: 0).from
  end

  test "rows that are not an array are the caller's defect" do
    assert_raises(ArgumentError) { Page.new(rows: nil, number: 1, total: 0) }
  end

  test "a number or a total that is not a number is the caller's defect" do
    assert_raises(ArgumentError) { Page.new(rows: [], number: "1", total: 0) }
    assert_raises(ArgumentError) { Page.new(rows: [], number: 1, total: "0") }
  end

  private
    def page(number: 1, total: 0)
      Page.new(rows: [], number: number, total: total)
    end
end

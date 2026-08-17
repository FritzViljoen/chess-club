require "test_helper"

class SearchTermTest < ActiveSupport::TestCase
  test "matches anywhere in the value" do
    assert_equal "%wyk%", SearchTerm.new("wyk").anywhere
  end

  test "is trimmed, because a trailing space is a typing accident" do
    assert_equal "%wyk%", SearchTerm.new("  wyk  ").anywhere
  end

  test "nothing typed is blank" do
    assert SearchTerm.new("").blank?
    assert SearchTerm.new("   ").blank?
    assert_not SearchTerm.new("wyk").blank?
  end

  test "a wildcard the person typed is escaped, so it means itself" do
    assert_equal "%100\\%%", SearchTerm.new("100%").anywhere
    assert_equal "%a\\_b%", SearchTerm.new("a_b").anywhere
    assert_equal "%c\\\\d%", SearchTerm.new("c\\d").anywhere
  end

  test "every column in a match carries the escape clause" do
    sql = SearchTerm.matching("name", "surname")

    assert_equal "name LIKE :term ESCAPE '\\' OR surname LIKE :term ESCAPE '\\'", sql
    assert_equal 2, sql.scan("ESCAPE").size, "expected no column to be the one that was forgotten"
  end
end

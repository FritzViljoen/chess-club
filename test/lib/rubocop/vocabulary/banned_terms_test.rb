require "benchmark"
require_relative "../cop_case"

class BannedTermsTest < CopCase
  polices RuboCop::Cop::Vocabulary::BannedTerms
  on_path "app/models/thing.rb"
  configured "BannedTerms" => %w[widget widgets]

  test "a banned term in a class name is an offense" do
    assert_source_offense "class Widget < ApplicationRecord\nend\n"
  end

  test "a banned term in a method name is an offense" do
    assert_source_offense "def widget_count\nend\n"
  end

  test "matching ignores case" do
    assert_source_offense "WIDGET = 1\n"
    assert_source_offense "Widget = 1\n"
    assert_source_offense "widget = 1\n"
  end

  test "the plural is its own entry, not an inflection" do
    assert_source_offense "widgets = []\n"
    assert_offenses "widgetry = []\n", 0
  end

  test "a term is matched on word boundaries only" do
    assert_offenses "rewidgeted = true\n", 0
    assert_offenses "miswidget = true\n", 0
    assert_offenses "widgeted = true\n", 0
  end

  test "an underscore-separated term still counts as a word" do
    assert_source_offense "spare_widget = nil\n"
    assert_source_offense "widget_id = nil\n"
  end

  test "comments and strings are policed too" do
    assert_source_offense "# every widget gets a score\n"
    assert_source_offense %(greeting = "welcome, widget"\n)
  end

  test "every occurrence is reported separately" do
    assert_offenses "widget = widgets.first\n", 2
  end

  test "the message names the term it found" do
    offense = offenses("class Widget; end\n").sole

    assert_includes offense.message, "Widget"
  end

  test "source with no banned term is accepted" do
    assert_offenses <<~RUBY, 0
      class Person < ApplicationRecord
        def score
          1200
        end
      end
    RUBY
  end

  test "an empty list polices nothing" do
    self.class.configured "BannedTerms" => []

    assert_offenses "class Widget; end\n", 0
  ensure
    self.class.configured "BannedTerms" => %w[widget widgets]
  end

  test "a CRLF file reports the offense where it actually is" do
    offense = offenses("X = 1\r\nY = 2\r\nwidget = 3\r\n").sole

    assert_equal 3, offense.location.line
    assert_equal 0, offense.location.column
    assert_equal "widget", offense.location.source
  end

  test "a CRLF offense on the last line stays inside the buffer" do
    source = ("# pad\r\n" * 20) + "widget = 1\r\n"
    offense = offenses(source).sole

    assert_equal 21, offense.location.line
    assert_equal "widget", offense.location.source
  end

  test "a non-ASCII character does not shift the offenses after it" do
    offense = offenses(%(x = "—"\nwidget = 1\n)).sole

    assert_equal 2, offense.location.line
    assert_equal 0, offense.location.column
    assert_equal "widget", offense.location.source
  end

  # The cost is per word, not per character: a scan that restarts from the top
  # of the string each time is only slow once there are many words to restart
  # for. One 40,000-character word is three iterations and finishes fast on the
  # quadratic implementation too, which is a test that guards nothing.
  test "scanning stays linear when the source is not ascii-only" do
    padding = %(# —#{"alpha beta gamma delta " * 8_000}\n)
    elapsed = Benchmark.realtime { offenses(padding + "widget = 1\n") }

    assert_operator elapsed, :<, 1.0, "scanning #{padding.length} chars took #{elapsed}s"
  end
end

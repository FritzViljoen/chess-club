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

  private
    def assert_source_offense(source, count: 1)
      assert_offenses source, count
    end
end

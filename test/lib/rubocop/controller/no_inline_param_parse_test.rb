require_relative "../cop_case"

class NoInlineParamParseTest < CopCase
  polices RuboCop::Cop::Controller::NoInlineParamParse
  on_path "app/controllers/rounds_controller.rb"

  test "parsing a date out of params is an offense" do
    assert_source_offense "Date.parse(params[:on])\n"
    assert_source_offense "DateTime.parse(params[:at])\n"
    assert_source_offense "Date.strptime(params[:on], \"%d %B %Y\")\n"
    assert_source_offense "Date.iso8601(params[:on])\n"
  end

  test "parsing a time in a zone the request did not name is an offense" do
    assert_source_offense "Time.zone.parse(params[:at])\n"
    assert_source_offense "Time.zone.strptime(params[:at], \"%H:%M\")\n"
  end

  test "a raising conversion of params is an offense" do
    assert_source_offense "Integer(params[:page])\n"
    assert_source_offense "Float(params[:fee])\n"
    assert_source_offense "BigDecimal(params[:fee])\n"
    assert_source_offense "Rational(params[:share])\n"
  end

  test "a raising cast on params is an offense" do
    assert_source_offense "params[:on].to_date\n"
    assert_source_offense "params[:at].to_datetime\n"
    assert_source_offense "params[:at].to_time\n"
  end

  test "a zone held any other way is still an inline parse" do
    assert_source_offense "time_zone_param!(:time_zone).parse(params[:at])\n"
    assert_source_offense "Time.find_zone!(params[:time_zone]).parse(params[:at])\n"
    assert_source_offense "ActiveSupport::TimeZone[params[:tz]].parse(params[:at])\n"
    assert_source_offense "zone.strptime(params[:at], \"%H:%M\")\n"
  end

  test "a parse that has no seam parser to be sent to is left alone" do
    assert_source_clean "JSON.parse(params[:payload])\n"
    assert_source_clean "URI.parse(params[:back_to])\n"
  end

  test "safe navigation is the same call, and raises the same way" do
    assert_source_offense "params[:on]&.to_date\n"
    assert_source_offense "params[:at]&.to_time\n"
    assert_source_offense "Time.zone&.parse(params[:at])\n"
    assert_source_clean "params[:page]&.then { |page| Integer(page) }\n"
  end

  test "a cast that names the zone it wants is still an inline parse" do
    assert_source_offense "params[:at].to_time(:local)\n"
    assert_source_offense "params[:at].to_time(:utc)\n"
  end

  # It reads Time.zone — the server's — and rolls a date the calendar does not
  # have over to the next month rather than refusing it.
  test "in_time_zone is the idiomatic spelling of the same defect" do
    assert_source_offense "params[:at].in_time_zone\n"
    assert_source_offense "params[:at]&.in_time_zone\n"
    assert_source_offense "params[:on].in_time_zone(\"Africa/Johannesburg\")\n"
  end

  test "params reached through anything still counts" do
    assert_source_offense "Integer(params.require(:filter)[:page])\n"
    assert_source_offense "Date.parse(params.fetch(:on, \"\"))\n"
  end

  test "the parsers this replaces are what a controller should call" do
    assert_source_clean "date_param!(:on)\n"
    assert_source_clean "time_param(:at, default: :now)\n"
    assert_source_clean "integer_param(:page, default: 1)\n"
  end

  test "a coercion that cannot raise is not this cop's business" do
    assert_source_clean "params[:page].to_i\n"
    assert_source_clean "params[:fee].to_f\n"
    assert_source_clean "params[:on].to_s\n"
  end

  test "parsing something that is not request input is left alone" do
    assert_source_clean "Date.parse(CUTOVER)\n"
    assert_source_clean "Integer(\"12\")\n"
    assert_source_clean "Time.zone.parse(round.starts_on)\n"
  end

  test "the message says what to call instead" do
    assert_includes offenses("Date.parse(params[:on])\n").first.message, "date_param"
  end
end

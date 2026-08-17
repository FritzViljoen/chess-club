require "test_helper"

class TypedParamsTest < ActiveSupport::TestCase
  # The parsers are private to a controller, so the test reaches them the way an
  # action does — through a controller that has included the concern.
  class Seam < ActionController::Base
    include TypedParams

    public :date_param, :date_param!, :time_param, :time_param!, :integer_param, :integer_param!,
      :decimal_param, :decimal_param!, :boolean_param, :boolean_param!, :enum_param, :enum_param!,
      :time_zone_param, :time_zone_param!
  end

  ALLOWED = %w[open closed].freeze

  # Two hours ahead of the process zone, so a time read in the wrong one is a
  # different instant. `ELSEWHERE` is a second zone, for the tests that show the
  # zone is what decided the answer.
  ZONE = "Africa/Johannesburg"
  ELSEWHERE = "Etc/UTC"

  test "a date is parsed, in the format the date fields post" do
    assert_equal Date.new(2026, 8, 17), seam(on: "17 August 2026").date_param(:on, time_zone: ZONE)
    assert_equal Date.new(2026, 8, 17), seam(on: "2026-08-17").date_param(:on, time_zone: ZONE)
  end

  test "a date that is not a date yields the default, never an exception" do
    assert_nil seam(on: "not a date").date_param(:on, time_zone: ZONE)
    assert_equal Date.new(2026, 1, 1), seam(on: "").date_param(:on, time_zone: ZONE, default: Date.new(2026, 1, 1))
    assert_equal Date.new(2026, 1, 1), seam({}).date_param(:on, time_zone: ZONE, default: Date.new(2026, 1, 1))
  end

  test "a date the calendar does not have is garbage, not a rounded date" do
    assert_nil seam(on: "2026-02-30").date_param(:on, time_zone: ZONE)
  end

  test "today is the named zone's today, not the process zone's" do
    travel_to Time.utc(2026, 8, 16, 23, 30) do
      assert_equal Date.new(2026, 8, 17), seam({}).date_param(:on, time_zone: ZONE, default: :today)
      assert_equal Date.new(2026, 8, 16), seam({}).date_param(:on, time_zone: ELSEWHERE, default: :today)
    end
  end

  test "a date parser will not run without a zone being named" do
    assert_raises(ArgumentError) { seam(on: "2026-08-17").date_param(:on) }
    assert_raises(ArgumentError) { seam(on: "2026-08-17").date_param!(:on) }
  end

  test "a time is parsed in the zone the caller named, never the process zone" do
    parsed = seam(at: "2026-08-17 10:30").time_param(:at, time_zone: ZONE)

    assert_equal Time.utc(2026, 8, 17, 8, 30), parsed.utc
    assert_equal ZONE, parsed.time_zone.name
    assert_not_equal Time.zone.parse("2026-08-17 10:30").utc, parsed.utc
  end

  test "the same string in another zone is another instant" do
    elsewhere = seam(at: "2026-08-17 10:30").time_param(:at, time_zone: ELSEWHERE)

    assert_equal Time.utc(2026, 8, 17, 10, 30), elsewhere.utc
  end

  test "a time that is not a time yields the default, never an exception" do
    assert_nil seam(at: "rubbish").time_param(:at, time_zone: ZONE)
    assert_equal Time.utc(2026, 1, 1), seam({}).time_param(:at, time_zone: ZONE, default: Time.utc(2026, 1, 1))
  end

  test "now is the named zone's now, carrying that zone" do
    travel_to Time.utc(2026, 8, 16, 23, 30) do
      assert_equal ZONE, seam({}).time_param(:at, time_zone: ZONE, default: :now).time_zone.name
      assert_equal Time.utc(2026, 8, 16, 23, 30), seam({}).time_param(:at, time_zone: ZONE, default: :now).utc
    end
  end

  test "a time the calendar does not have does not roll over" do
    assert_nil seam(at: "2026-02-30 10:00").time_param(:at, time_zone: ZONE)
  end

  test "a time stating an offset that disagrees with the zone bounces" do
    error = assert_raises(TypedParams::BadParam) do
      seam(at: "2026-08-17T10:30:00+05:00").time_param(:at, time_zone: ZONE)
    end

    assert_equal :at, error.key
    assert_raises(TypedParams::BadParam) { seam(at: "2026-08-17 10:30 UTC").time_param(:at, time_zone: ZONE) }
  end

  test "a time stating the same offset as the zone is the same answer twice" do
    parsed = seam(at: "2026-08-17T10:30:00+02:00").time_param(:at, time_zone: ZONE)

    assert_equal Time.utc(2026, 8, 17, 8, 30), parsed.utc
    assert_equal ZONE, parsed.time_zone.name
  end

  test "a disagreement bounces from the plain form too, default or not" do
    assert_raises(TypedParams::BadParam) do
      seam(at: "2026-08-17T10:30:00+05:00").time_param(:at, time_zone: ZONE, default: :now)
    end
  end

  test "a time parser will not run without a zone being named" do
    assert_raises(ArgumentError) { seam(at: "2026-08-17 10:30").time_param(:at) }
    assert_raises(ArgumentError) { seam(at: "2026-08-17 10:30").time_param!(:at) }
  end

  test "a parser takes a key, a name, or the zone that name was cast into" do
    controller = seam(on: "2026-08-17", time_zone: ZONE)
    on = Date.new(2026, 8, 17)

    assert_equal on, controller.date_param(:on, time_zone: :time_zone)
    assert_equal on, controller.date_param(:on, time_zone: ZONE)
    assert_equal on, controller.date_param(:on, time_zone: controller.time_zone_param!(:time_zone))
  end

  test "a key reads that parameter, whatever it is called" do
    controller = seam(at: "2026-08-17 10:30", tz: ZONE)

    assert_equal Time.utc(2026, 8, 17, 8, 30), controller.time_param(:at, time_zone: :tz).utc
  end

  test "a key naming a parameter that did not arrive bounces on that key" do
    error = assert_raises(TypedParams::BadParam) do
      seam(on: "2026-08-17").date_param(:on, time_zone: :tz)
    end

    assert_equal :tz, error.key
  end

  test "anything that is not a name a zone answers to bounces the requester" do
    error = assert_raises(TypedParams::BadParam) do
      seam(at: "2026-08-17 10:30").time_param(:at, time_zone: "Mars/Olympus")
    end

    assert_equal :time_zone, error.key

    [ "", nil, [ "Etc/UTC" ] ].each do |sent|
      assert_raises(TypedParams::BadParam, "#{sent.inspect} is not a zone name") do
        seam(on: "2026-08-17").date_param(:on, time_zone: sent)
      end
    end
  end

  test "a parser that reads no date or time names no zone" do
    assert_equal 12, seam(page: "12").integer_param(:page)
  end

  test "a zone parameter answers with the zone itself" do
    assert_equal ActiveSupport::TimeZone[ZONE], seam(time_zone: ZONE).time_zone_param(:time_zone)
  end

  test "a name no zone answers to yields the default, never an exception" do
    assert_nil seam(time_zone: "Mars/Olympus").time_zone_param(:time_zone)
    assert_nil seam({}).time_zone_param(:time_zone)
    assert_equal ActiveSupport::TimeZone[ZONE], seam({}).time_zone_param(:time_zone, default: ActiveSupport::TimeZone[ZONE])
  end

  test "the bang form bounces a requester whose zone did not arrive" do
    error = assert_raises(TypedParams::BadParam) { seam({}).time_zone_param!(:time_zone) }

    assert_equal :time_zone, error.key
    assert_raises(TypedParams::BadParam) { seam(time_zone: "Mars/Olympus").time_zone_param!(:time_zone) }
  end

  test "an integer is strict, not coerced" do
    assert_equal 12, seam(page: "12").integer_param(:page)
    assert_nil seam(page: "12abc").integer_param(:page)
    assert_nil seam(page: "0x1f").integer_param(:page)
  end

  test "a decimal is exact and finite" do
    assert_equal BigDecimal("2.35"), seam(fee: "2.35").decimal_param(:fee)
    assert_nil seam(fee: "Infinity").decimal_param(:fee)
    assert_nil seam(fee: "NaN").decimal_param(:fee)
  end

  test "a boolean is only what a form or an api actually posts" do
    assert_equal true, seam(only_open: "1").boolean_param(:only_open)
    assert_equal true, seam(only_open: "true").boolean_param(:only_open)
    assert_equal false, seam(only_open: "0").boolean_param(:only_open)
    assert_equal false, seam(only_open: "false").boolean_param(:only_open)
    assert_nil seam(only_open: "yes").boolean_param(:only_open)
  end

  test "a boolean that arrived as a real boolean is kept" do
    assert_equal false, seam(only_open: false).boolean_param(:only_open)
    assert_equal true, seam(only_open: true).boolean_param(:only_open)
  end

  test "a false boolean is a value, so the bang form does not reject it" do
    assert_equal false, seam(only_open: "0").boolean_param!(:only_open)
  end

  test "an enum passes only a value from the closed set" do
    assert_equal "open", seam(state: "open").enum_param(:state, ALLOWED)
    assert_nil seam(state: "elsewhere").enum_param(:state, ALLOWED)
    assert_equal "open", seam({}).enum_param(:state, ALLOWED, default: "open")
  end

  test "every bang form raises for the requester, not for the developer" do
    error = assert_raises(TypedParams::BadParam) { seam(on: "rubbish").date_param!(:on, time_zone: ZONE) }

    assert_equal :on, error.key
    assert_raises(TypedParams::BadParam) { seam(at: "rubbish").time_param!(:at, time_zone: ZONE) }
    assert_raises(TypedParams::BadParam) { seam(page: "rubbish").integer_param!(:page) }
    assert_raises(TypedParams::BadParam) { seam(fee: "rubbish").decimal_param!(:fee) }
    assert_raises(TypedParams::BadParam) { seam(only_open: "rubbish").boolean_param!(:only_open) }
    assert_raises(TypedParams::BadParam) { seam(state: "rubbish").enum_param!(:state, ALLOWED) }
  end

  test "a bang form is satisfied by good input" do
    assert_equal 12, seam(page: "12").integer_param!(:page)
  end

  private
    def seam(params = {}, **keywords)
      Seam.new.tap { |controller| controller.params = ActionController::Parameters.new(params.merge(keywords)) }
    end
end

# Input the requester got wrong bounces, and never reaches the domain or a 500.
class TypedParamsBounceTest < ActionController::TestCase
  class BounceController < ActionController::Base
    include TypedParams

    def show
      render plain: integer_param!(:page)
    end

    # An action that wants the requester's own zone asks for it.
    def on
      render plain: date_param!(:on, time_zone: :time_zone)
    end
  end

  tests BounceController

  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get "show", to: "typed_params_bounce_test/bounce#show"
      get "on", to: "typed_params_bounce_test/bounce#on"
    end
  end

  test "good input reaches the action" do
    get :show, params: { page: "2" }

    assert_response :success
    assert_equal "2", response.body
  end

  test "an html request goes back with a message naming the parameter" do
    get :show, params: { page: "rubbish" }

    assert_redirected_to "/"
    assert_equal "Please provide a valid page and try again.", flash[:alert]
  end

  test "anything else gets a plain 400" do
    get :show, params: { page: "rubbish" }, format: :json

    assert_response :bad_request
    assert_empty response.body
  end

  test "a missing parameter bounces the same way as a bad one" do
    get :show

    assert_redirected_to "/"
  end

  test "an action that asked for the requester's zone bounces without one" do
    get :on, params: { on: "2026-08-17" }

    assert_redirected_to "/"
    assert_equal "Please provide a valid time zone and try again.", flash[:alert]
  end

  test "the same request with the zone reaches the action" do
    get :on, params: { on: "2026-08-17", time_zone: "Africa/Johannesburg" }

    assert_response :success
    assert_equal "2026-08-17", response.body
  end
end

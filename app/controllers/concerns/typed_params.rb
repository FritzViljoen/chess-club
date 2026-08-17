# Parsing for request parameters, done once, at the seam.
#
# Everything arriving over HTTP is a string somebody else typed. It becomes a
# Date, an Integer or a boolean here — never inline in an action, where
# `Date.parse(params[:on])` turns a typo into a 500, and never in the domain,
# which is handed real values (`TypedArguments`).
#
# Every parser comes in two forms:
#
#   integer_param(:page, default: 1)   # missing or unparseable → the default
#   integer_param!(:page)              # missing or unparseable → BadParam
#
# `BadParam` bounces the requester: an HTML request goes back where it came from
# with a flash, anything else gets a plain 400.
#
# Nothing here coerces quietly: `"12abc"` is not 12 and `"yes"` is not true.
#
# A date or a time is read in a zone the caller names:
#
#   date_param!(:on, time_zone: :time_zone)              # a parameter to read
#   time_param(:at, time_zone: "Africa/Johannesburg")    # an IANA name
#
# A symbol is the parameter to take the zone from, a string is the zone's name,
# and a zone `time_zone_param` already cast is understood too. All four parsers
# require it and nothing supplies a default — not `Time.zone`, not a configured
# setting, and not the request unasked. Forgetting it is an `ArgumentError` where
# it was forgotten; `:today` and `:now` resolve in the named zone, so an action
# never reaches for `Date.current`.
module TypedParams
  extend ActiveSupport::Concern

  # Narrower than rescuing `ArgumentError`, which would turn a real defect into a
  # 400 and hide it.
  class BadParam < StandardError
    attr_reader :key

    def initialize(key)
      @key = key
      super("bad or missing parameter: #{key}")
    end
  end

  included do
    # Bad input is the requester's problem, never a 500.
    rescue_from BadParam do |bad_param|
      respond_to do |format|
        format.html do
          flash[:alert] = "Please provide a valid #{bad_param.key.to_s.humanize.downcase} and try again."
          redirect_back fallback_location: "/"
        end
        format.any { head :bad_request }
      end
    end
  end

  private
    # `Date.parse`, not `Date.iso8601`: a date field posts what a person can read
    # — "17 August 2026" — and a named month has no dd/mm ambiguity.
    #
    # A date needs the zone even though it carries none: at 00:30 UTC it is
    # already tomorrow two zones east, so `default: :today` needs one to answer.
    def date_param(key, time_zone:, default: nil)
      zone = named_zone(time_zone)

      parsed_param(key, default == :today ? zone.today : default) { |raw| Date.parse(raw) }
    end

    def date_param!(key, time_zone:)
      date_param(key, time_zone: time_zone) || raise(BadParam, key)
    end

    # Strict about the calendar first: `TimeZone#parse` rolls "2026-02-30 10:00"
    # over to 2 March, where `DateTime.parse` raises. A typo must bounce, not
    # become a different valid time.
    #
    # The two failures have different shapes — one raises, the other answers nil —
    # so the default is applied to what comes back rather than inside the block.
    def time_param(key, time_zone:, default: nil)
      zone = named_zone(time_zone)
      parsed = parsed_param(key, nil) do |raw|
        DateTime.parse(raw)
        zone.parse(raw).tap { |at| refuse_conflicting_zone(key, raw, at) }
      end

      parsed || (default == :now ? zone.now : default)
    end

    def time_param!(key, time_zone:)
      time_param(key, time_zone: time_zone) || raise(BadParam, key)
    end

    # Strict base 10: `"12abc"` is garbage, not 12, and `to_i` would say 12.
    def integer_param(key, default: nil)
      parsed_param(key, default) { |raw| Integer(raw, 10) }
    end

    def integer_param!(key)
      integer_param(key) || raise(BadParam, key)
    end

    # BigDecimal, never Float — these are amounts. BigDecimal parses "Infinity"
    # and "NaN" happily; neither is one.
    def decimal_param(key, default: nil)
      parsed_param(key, default) do |raw|
        BigDecimal(raw).tap { |parsed| raise ArgumentError, "not finite: #{raw.inspect}" unless parsed.finite? }
      end
    end

    def decimal_param!(key)
      decimal_param(key) || raise(BadParam, key)
    end

    # Only what a form or an API actually posts — "1"/"0" from a checkbox,
    # "true"/"false" from JSON. A real boolean short-circuits, because the blank
    # guard below would eat `false` and hand back the default.
    def boolean_param(key, default: nil)
      raw = params[key]
      return raw if raw == true || raw == false

      parsed_param(key, default) do |parsed|
        case parsed
        when "1", "true"  then true
        when "0", "false" then false
        else raise ArgumentError, "not a boolean: #{parsed.inspect}"
        end
      end
    end

    # `false` is an answer, so this guards on nil. `|| raise` would reject an
    # honest "0".
    def boolean_param!(key)
      value = boolean_param(key)
      raise BadParam, key if value.nil?

      value
    end

    # A closed set of literal values — these end up in file names, redirects and
    # SQL fragments, so never passthrough.
    def enum_param(key, allowed, default: nil)
      parsed_param(key, default) do |raw|
        allowed.include?(raw) ? raw : raise(ArgumentError, "not one of #{allowed.join(", ")}: #{raw.inspect}")
      end
    end

    def enum_param!(key, allowed)
      enum_param(key, allowed) || raise(BadParam, key)
    end

    # An IANA identifier — what `Intl.DateTimeFormat().resolvedOptions().timeZone`
    # gives a browser — rather than an offset in minutes, which is only true for
    # part of the year.
    #
    # This answers with the zone itself, for an action that has to render in it or
    # hand it on. A date or time parser needs none of it: `time_zone: :time_zone`
    # has the parser read the parameter.
    def time_zone_param(key, default: nil)
      parsed_param(key, default) do |raw|
        ActiveSupport::TimeZone[raw] || raise(ArgumentError, "not a zone: #{raw.inspect}")
      end
    end

    def time_zone_param!(key)
      time_zone_param(key) || raise(BadParam, key)
    end

    # A time string may state its own offset. Where it disagrees with the zone
    # asked for, the request holds two answers: `TimeZone#parse` would honour the
    # string's and hand back an instant hours from the one meant.
    #
    # It bounces rather than raising — contradictory input is still input — and it
    # bounces from the plain form too, where a default would answer a question
    # nobody meant to ask. Agreement is fine: "+02:00" read in Johannesburg says
    # the same thing twice.
    def refuse_conflicting_zone(key, raw, at)
      stated = Date._parse(raw)[:offset]

      raise BadParam, key if stated && stated != at.utc_offset
    end

    # A key, a name, or a zone already cast — the stages of one cast, and this
    # module exists to move a value along it.
    #
    # Everything else is one failure: missing, blank, misspelt, or an array where
    # a name was expected all bounce, because the usual source is the request and
    # a request may send anything.
    def named_zone(time_zone)
      time_zone = time_zone_param!(time_zone) if time_zone.is_a?(Symbol)
      zone = ActiveSupport::TimeZone[time_zone] if time_zone.is_a?(String) || time_zone.is_a?(ActiveSupport::TimeZone)

      zone || raise(BadParam, :time_zone)
    end

    # Blank or unparseable input yields the default; the caller decides what that
    # means. The rescue wraps the block's parse and nothing else, so it can never
    # swallow an ArgumentError raised somewhere further in.
    def parsed_param(key, default)
      raw = params[key]
      return default if raw.blank?

      yield(raw.to_s)
    rescue ArgumentError
      default
    end
end

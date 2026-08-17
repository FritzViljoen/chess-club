module TypedParams
  extend ActiveSupport::Concern

  class BadParam < StandardError
    attr_reader :key

    def initialize(key)
      @key = key
      super("bad or missing parameter: #{key}")
    end
  end

  included do
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
    def date_param(key, time_zone:, default: nil)
      zone = named_zone(time_zone)

      parsed_param(key, default == :today ? zone.today : default) { |raw| Date.parse(raw) }
    end

    def date_param!(key, time_zone:)
      date_param(key, time_zone: time_zone) || raise(BadParam, key)
    end

    def time_param(key, time_zone:, default: nil)
      zone = named_zone(time_zone)
      # `zone.parse` answers nil for rubbish rather than raising, and nil here is
      # indistinguishable from "not supplied". `DateTime.parse` raises, so the
      # bad input reaches the rescue instead of passing as an absent one.
      parsed = parsed_param(key, nil) do |raw|
        DateTime.parse(raw)
        zone.parse(raw).tap { |at| refuse_conflicting_zone(key, raw, at) }
      end

      parsed || (default == :now ? zone.now : default)
    end

    def time_param!(key, time_zone:)
      time_param(key, time_zone: time_zone) || raise(BadParam, key)
    end

    def integer_param(key, default: nil)
      parsed_param(key, default) { |raw| Integer(raw, 10) }
    end

    def integer_param!(key)
      integer_param(key) || raise(BadParam, key)
    end

    def decimal_param(key, default: nil)
      parsed_param(key, default) do |raw|
        BigDecimal(raw).tap { |parsed| raise ArgumentError, "not finite: #{raw.inspect}" unless parsed.finite? }
      end
    end

    def decimal_param!(key)
      decimal_param(key) || raise(BadParam, key)
    end

    def boolean_param(key, default: nil)
      # Before the blank guard, because `false.blank?` is true and a genuine
      # `false` would otherwise come back as the default.
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

    def boolean_param!(key)
      value = boolean_param(key)
      raise BadParam, key if value.nil?

      value
    end

    # Over the limit refuses outright rather than falling back to the default:
    # the default here is "no search", so a silent fallback would answer an
    # over-long search with the whole list — the broadest possible answer to a
    # question nobody asked.
    def text_param(key, default: "", limit: 200)
      raw = params[key]
      return default unless raw.is_a?(String)

      trimmed = raw.strip
      return default if trimmed.empty?
      raise BadParam, key if trimmed.length > limit

      trimmed
    end

    def text_param!(key, limit: 200)
      value = text_param(key, default: nil, limit: limit)

      value || raise(BadParam, key)
    end

    def enum_param(key, allowed, default: nil)
      parsed_param(key, default) do |raw|
        allowed.include?(raw) ? raw : raise(ArgumentError, "not one of #{allowed.join(", ")}: #{raw.inspect}")
      end
    end

    def enum_param!(key, allowed)
      enum_param(key, allowed) || raise(BadParam, key)
    end

    def time_zone_param(key, default: nil)
      parsed_param(key, default) do |raw|
        ActiveSupport::TimeZone[raw] || raise(ArgumentError, "not a zone: #{raw.inspect}")
      end
    end

    def time_zone_param!(key)
      time_zone_param(key) || raise(BadParam, key)
    end

    # `2026-03-03T18:00+05:00` read in Johannesburg states two answers. Refuse
    # rather than silently keep one.
    def refuse_conflicting_zone(key, raw, at)
      stated = Date._parse(raw)[:offset]

      raise BadParam, key if stated && stated != at.utc_offset
    end

    def named_zone(time_zone)
      time_zone = time_zone_param!(time_zone) if time_zone.is_a?(Symbol)
      zone = ActiveSupport::TimeZone[time_zone] if time_zone.is_a?(String) || time_zone.is_a?(ActiveSupport::TimeZone)

      zone || raise(BadParam, :time_zone)
    end

    def parsed_param(key, default)
      raw = params[key]
      return default if raw.blank?

      yield(raw.to_s)
    rescue ArgumentError
      default
    end
end

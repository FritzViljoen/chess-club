# frozen_string_literal: true

module RuboCop
  module Cop
    module Controller
      # Request parameters are parsed through `TypedParams`, never inline.
      #
      # `Date.parse(params[:on])` turns a typo into a 500, and
      # `Time.zone.parse(params[:at])` reads the requester's time in the server's
      # zone — an answer an hour or two out that looks entirely right.
      #
      # Flagged whenever the parsed value comes from `params`: `parse`,
      # `strptime` and `iso8601` on any receiver, the raising `Kernel`
      # conversions, and the casts — `to_date`, `to_datetime`, `to_time` and
      # `in_time_zone`. `to_i` and `to_f` cannot raise and read no zone, so they
      # are not this cop's business — nor is parsing a string that did not come
      # from the request.
      #
      # @example
      #   # bad
      #   Date.parse(params[:on])
      #   Time.zone.parse(params[:at])
      #   Integer(params[:page])
      #   params[:on].to_date
      #   params[:at].in_time_zone
      #
      #   # good
      #   date_param!(:on)
      #   time_param(:at, default: :now)
      #   integer_param(:page, default: 1)
      #   params[:page].to_i
      #   Date.parse(CUTOVER)
      class NoInlineParamParse < Base
        MSG = "Parse request input with the `TypedParams` parsers — " \
              "`date_param`, `time_param`, `integer_param`, `decimal_param`, " \
              "`boolean_param`, `enum_param`, plain or bang — not inline " \
              "`%<code>s`. Bad input has to bounce, and a time has to be read " \
              "in the requester's zone."

        RESTRICT_ON_SEND = %i[
          parse strptime iso8601
          Integer Float BigDecimal Rational
          to_date to_datetime to_time in_time_zone
        ].freeze

        # Any receiver, because a zone is held in more ways than one:
        # `Time.zone`, `Time.find_zone!(…)`, `ActiveSupport::TimeZone[…]`, or
        # whatever `time_zone_param!` answered with.
        def_node_matcher :parse_call?, <<~PATTERN
          ({send csend} _ {:parse :strptime :iso8601} ...)
        PATTERN

        def_node_matcher :kernel_conversion?, <<~PATTERN
          ({send csend} {nil? (const {nil? cbase} :Kernel)} {:Integer :Float :BigDecimal :Rational} ...)
        PATTERN

        # Arguments and all: `params[:at].to_time(:local)` is the server's zone
        # written out in full. `in_time_zone` is the idiomatic spelling of the
        # same thing — it answers in `Time.zone` and rolls "2026-02-30 10:00"
        # over to 2 March rather than refusing it.
        def_node_matcher :cast?, <<~PATTERN
          ({send csend} !nil? {:to_date :to_datetime :to_time :in_time_zone} ...)
        PATTERN

        # Not every `.parse` is a time. These two take request input for their
        # own reasons and have no `TypedParams` parser to be sent to.
        NOT_TIME = %w[JSON URI].freeze

        def on_send(node)
          if (parse_call?(node) && !exempt_receiver?(node)) || kernel_conversion?(node)
            return unless node.arguments.any? { |argument| from_params?(argument) }

            add_offense(node, message: format(MSG, code: "#{receiver_source(node)}#{node.method_name}(params[...])"))
          elsif cast?(node)
            return unless from_params?(node.receiver)

            add_offense(node, message: format(MSG, code: "params[...].#{node.method_name}"))
          end
        end

        # `params[:on]&.to_date` raises on "rubbish" like its plain sibling.
        alias_method :on_csend, :on_send

        private
          def exempt_receiver?(node)
            node.receiver&.const_type? && NOT_TIME.include?(node.receiver.const_name)
          end

          def receiver_source(node)
            node.receiver ? "#{node.receiver.source}." : ""
          end

          # `params` anywhere inside the value — directly, through `require`, or
          # out of a nested read.
          def from_params?(node)
            return false unless node
            return true if params?(node)

            node.each_descendant(:send, :csend).any? { |call| params?(call) }
          end

          def params?(node)
            (node.send_type? || node.csend_type?) && node.method_name == :params && node.receiver.nil?
          end
      end
    end
  end
end

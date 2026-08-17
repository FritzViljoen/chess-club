# frozen_string_literal: true

module RuboCop
  module Cop
    module Service
      # Every keyword a `Service` takes is type-checked inline, through one of
      # the `TypedArguments` guards. An unguarded keyword is an untyped input, and the
      # service is the last place that can say "this is not a Date" while the
      # caller is still standing there.
      #
      # The initializer is hand-written: a macro declaring the inputs would hide
      # the assignment and the assertion both, and `typed(on, Date)` greps.
      #
      # Anything that is not a named keyword is its own offense. `**options`
      # guards nothing it accepts; `*args` and `options = {}` are worse, because
      # `Service.call(**arguments)` hands its keywords to a keyword-less
      # initializer as one positional Hash and the call succeeds.
      #
      # @example
      #   # bad
      #   class ArchiveRound < Service
      #     def initialize(round:, on:)
      #       @round = typed(round, Round)
      #       @on = on
      #     end
      #   end
      #
      #   # good
      #   class ArchiveRound < Service
      #     def initialize(round:, on:, at:, kind:, entrants:)
      #       @round = typed(round, Round)
      #       @on = typed(on, Date)
      #       @at = typed(at, ActiveSupport::TimeWithZone)
      #       @kind = typed_enum(kind, KINDS)
      #       @entrants = typed_array(entrants, Person)
      #     end
      #   end
      class NoUnguardedArguments < Base
        MSG = "Guard `%<keyword>s` with `typed(%<keyword>s, <Type>)` — or " \
              "`typed_enum` for a closed set of values, `typed_array` and " \
              "`typed_hash` for a collection. An unguarded keyword is an " \
              "untyped input."

        # By base class rather than by folder: a service stays covered wherever
        # it is filed.
        BASE = "Service"

        MSG_SPLAT = "Name each keyword this service takes. `**` accepts " \
                    "anything a caller passes and guards none of it."

        MSG_POSITIONAL = "A service takes named keywords. A positional " \
                         "parameter collects whatever arrives — including the " \
                         "keywords `Service.call` forwards, which Ruby hands " \
                         "over as one Hash — and no guard can name it."

        GUARDS = %i[typed typed_enum typed_array typed_hash].freeze

        # `initialize(round)`, `initialize(round = nil)`, `initialize(*args)`,
        # and `initialize(...)`, which forwards everything and guards none of it.
        POSITIONAL = %i[arg optarg restarg forward_arg].freeze

        def on_def(node)
          return unless node.method_name == :initialize
          return unless service?(node)

          guarded = guarded_names(node)

          node.arguments.each do |argument|
            next add_offense(argument, message: MSG_SPLAT) if argument.kwrestarg_type?
            next add_offense(argument, message: MSG_POSITIONAL) if POSITIONAL.include?(argument.type)
            next unless argument.kwarg_type? || argument.kwoptarg_type?

            keyword = argument.children.first
            next if guarded.include?(keyword)

            add_offense(argument, message: format(MSG, keyword: keyword))
          end
        end

        private
          # `Rounds::Service` is a `Service`.
          def service?(definition)
            klass = definition.each_ancestor(:class).first
            return false unless klass

            klass.parent_class&.const_name&.split("::")&.last == BASE
          end

          # The first argument of each guard call is the value being asserted, so
          # a guard applied to something else covers no keyword.
          def guarded_names(definition)
            definition.each_descendant(:send).filter_map do |send|
              next unless GUARDS.include?(send.method_name) && send.receiver.nil?

              asserted = send.first_argument
              asserted.children.first if asserted&.lvar_type?
            end
          end
      end
    end
  end
end

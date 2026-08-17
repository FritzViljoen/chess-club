# frozen_string_literal: true

module RuboCop
  module Cop
    module Controller
      # A request parameter reaches a record through `TypedParams`, never raw.
      #
      # `Person.find(params[:id])` works, which is the trap: Active Record
      # coerces the string, so `/people/1abc` serves person 1 and nothing
      # anywhere fails. `integer_param!` refuses it. The parsers cannot defend a
      # door nobody opened, so this cop is what makes them unavoidable.
      #
      # Flagged wherever a value derived from `params` is handed to a finder or
      # a writer — as an argument, inside a hash, or nested any depth down,
      # including through a `*_params` helper. A parsed value is fine, because
      # the parser is the call that arrives, not `params`.
      #
      # @example
      #   # bad
      #   Person.find(params[:id])
      #   Person.find_by(id: params[:id])
      #   Contest.where(person_id: params[:person_id])
      #   Person.new(params[:person])
      #
      #   # good
      #   Person.find(integer_param!(:id))
      #   Person.find_by(id: integer_param!(:id))
      #   Contest.where(person_id: integer_param!(:person_id))
      #   Person.new
      class NoUnparsedLookup < Base
        MSG = "Read `%<parameter>s` with a `TypedParams` parser before it " \
              "reaches `%<method>s`. Active Record coerces a raw string, so " \
              "`1abc` finds record 1 and nothing fails."

        RESTRICT_ON_SEND = %i[
          find find_by find_by! where new create create! update update!
          find_or_create_by find_or_create_by! find_or_initialize_by exists?
        ].freeze

        # A `*_params` helper is the conventional Rails hiding place for
        # `params`, and one extraction would otherwise blind a purely syntactic
        # cop. Treated as `params` itself. Plural only: the seam's own parsers
        # are singular (`integer_param`), and they are the way out, not in.
        PARAMS_HELPER = /_params\z/

        def on_send(node)
          return unless node.receiver
          return unless node.arguments.any? { |argument| from_params?(argument) }

          add_offense(node, message: format(MSG, parameter: "params[...]", method: node.method_name))
        end

        alias_method :on_csend, :on_send

        private
          def from_params?(node)
            return false unless node
            return true if params?(node)

            node.each_descendant(:send, :csend).any? { |call| params?(call) }
          end

          def params?(node)
            return false unless node.send_type? || node.csend_type?
            return false if node.receiver

            node.method_name == :params || node.method_name.match?(PARAMS_HELPER)
          end
      end
    end
  end
end

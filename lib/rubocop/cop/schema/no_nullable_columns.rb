# frozen_string_literal: true

module RuboCop
  module Cop
    module Schema
      # Every column must end the migration declared `null: false`.
      #
      # A nullable column makes every read ambiguous: the caller cannot tell
      # "no value yet", "not applicable" and "we lost it" apart, so the
      # ambiguity is pushed out to every call site as a nil check. Tony Hoare
      # called the null reference he introduced in ALGOL W his billion-dollar
      # mistake for exactly this reason. Keep it out of the schema and the
      # ambiguity never reaches Ruby.
      #
      # If a column genuinely has no value for some rows, that is a missing
      # table, not a missing value.
      #
      # A NOT NULL column cannot be added to a table that already holds rows in
      # one statement, so the three-step form is allowed: add the column
      # nullable, fill it, then promote it with `change_column_null`. The
      # promotion has to come later in the same method — a nullable column that
      # outlives its migration is what this cop exists to prevent, and a
      # promotion in `down` promotes nothing in `up`.
      #
      # The reverse direction is exempt. `down` restores the previous schema,
      # which is exactly the state this cop forbids going to; forbidding it
      # there would make a reversible migration unwritable.
      #
      # @example
      #   # bad
      #   t.string :email
      #   t.string :email, null: true
      #   add_column :people, :email, :string
      #   change_column_null :people, :email, true
      #   change_column :people, :email, :text
      #   t.timestamps null: true
      #
      #   # good
      #   t.string :email, null: false
      #   add_column :people, :email, :string, null: false
      #   change_column :people, :email, :text, null: false
      #   t.timestamps
      #
      #   # good — the three steps, in one method, in order
      #   add_column :people, :email, :string
      #   Person.update_all(email: "")
      #   change_column_null :people, :email, false
      class NoNullableColumns < Base
        include ColumnDefinition

        MSG = "Declare `null: false`. A nullable column makes every read " \
              "ambiguous and pushes a nil check to every call site."

        MSG_NULLABLE_AGAIN = "Do not make a column nullable again. Every read " \
                             "of it becomes ambiguous from here on."

        MSG_UNPROMOTED = "This column is left nullable. Fill it and promote it " \
                         "with `change_column_null` later in this same method."

        RESTRICT_ON_SEND = COLUMN_SENDS

        def on_send(node)
          return if reversing?(node)

          case column_send_kind(node)
          when :create then on_column_added(node)
          when :alter then add_offense(node) unless null_false?(node)
          when :null_change then add_offense(node, message: MSG_NULLABLE_AGAIN) unless promotion?(node)
          when :timestamps then add_offense(node) if reopened_as_nullable?(node)
          end
        end

        private
          def on_column_added(node)
            return if null_false?(node)

            identities = column_identities(node)
            return if identities.any? && identities.all? { |identity| promoted_after?(node, identity) }

            add_offense(node, message: promotable?(node) ? MSG_UNPROMOTED : MSG)
          end

          # A reference contributes `_id` (and `_type` when polymorphic), so all
          # of its columns have to be promoted, not just one.
          def promoted_after?(node, identity)
            later_sends_of_kind(node, :null_change).any? do |send|
              promotion?(send) && column_identities(send).include?(identity)
            end
          end

          # Whether the three-step form is even available here. Inside
          # `create_table` the table is new and therefore empty, so a nullable
          # column has no excuse.
          def promotable?(node)
            !block_form?(node) || !inside_create_table?(node)
          end

          def inside_create_table?(node)
            node.each_ancestor(:block).any? do |ancestor|
              ancestor.send_node.receiver.nil? && ancestor.send_node.method?(:create_table)
            end
          end

          def null_false?(node)
            column_option(node, :null)&.value&.false_type? || false
          end

          # `t.timestamps` and `add_timestamps` are NOT NULL already; only an
          # explicit `null:` that is not `false` reopens the question.
          def reopened_as_nullable?(node)
            pair = column_option(node, :null)
            !pair.nil? && !pair.value.false_type?
          end

          # `change_column_null :people, :email, false` — the promotion this
          # cop wants. Anything else is a column going nullable.
          def promotion?(node)
            value_argument(node)&.false_type? || false
          end
      end
    end
  end
end

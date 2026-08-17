# frozen_string_literal: true

module RuboCop
  module Cop
    module Schema
      # Shared recognition of the migration calls that decide a column's
      # nullability or its default, for the cops that police the schema.
      #
      # Every such call falls into one of five kinds:
      #
      #   :create         a column is added          `t.string :email`
      #   :alter          a column is redefined      `change_column :m, :e, :string`
      #   :null_change    only nullability changes   `change_column_null :m, :e, false`
      #   :default_change only the default changes   `change_column_default :m, :e, to: 0`
      #   :timestamps     `created_at` / `updated_at`
      #
      # Each kind exists in two forms: called on the table object inside a
      # `create_table` or `change_table` block, or called on the migration
      # itself. Both are recognised; anything with some other receiver is
      # somebody else's method call.
      module ColumnDefinition
        # `t.string :email` and friends.
        COLUMN_TYPES = %i[
          belongs_to bigint binary blob boolean column date datetime decimal
          float inet integer interval json jsonb numeric references string
          text time timestamp uuid virtual
        ].freeze

        # These name an association, not a column: `t.references :group` creates
        # `group_id`, and a polymorphic one creates `group_type` alongside it.
        REFERENCE_TYPES = %i[references belongs_to add_reference add_belongs_to].freeze

        BLOCK_KINDS = COLUMN_TYPES.to_h { |type| [ type, :create ] }.merge(
          change: :alter,
          change_null: :null_change,
          change_default: :default_change,
          timestamps: :timestamps
        ).freeze

        MIGRATION_KINDS = {
          add_column: :create,
          add_reference: :create,
          add_belongs_to: :create,
          add_timestamps: :timestamps,
          change_column: :alter,
          change_column_null: :null_change,
          change_column_default: :default_change
        }.freeze

        COLUMN_SENDS = (BLOCK_KINDS.keys | MIGRATION_KINDS.keys).freeze

        # The blocks that name the table their body defines columns on.
        TABLE_BLOCKS = %i[create_table change_table].freeze

        # Every block that yields a table object. `drop_table` and
        # `create_join_table` yield one too, they just do not name a table the
        # columns can be attributed to.
        TABLE_OBJECT_BLOCKS = %i[create_table change_table drop_table create_join_table].freeze

        # Most block-form calls name as many columns as you give them:
        # `t.string :email, :nickname` defines both. These four are the
        # exception — their second argument is a type or a value, not another
        # column.
        SINGLE_NAME_BLOCK_SENDS = %i[column change change_null change_default].freeze

        private
          # Which of the five kinds this call is, or nil if it is not a column
          # call at all.
          def column_send_kind(node)
            if node.receiver.nil?
              MIGRATION_KINDS[node.method_name]
            elsif table_object?(node.receiver)
              BLOCK_KINDS[node.method_name]
            end
          end

          # Whether a receiver is the table object a `create_table` and friends
          # yielded, rather than any other local that happens to answer one of
          # these names. `cutoff.change(hour: 0)` is `Time#change`, not a column
          # being redefined.
          def table_object?(receiver)
            return false unless receiver.lvar_type?

            name = receiver.children.first

            receiver.each_ancestor(:block).any? do |ancestor|
              send = ancestor.send_node

              send.receiver.nil? &&
                TABLE_OBJECT_BLOCKS.include?(send.method_name) &&
                ancestor.arguments.first&.name == name
            end
          end

          def block_form?(node)
            !node.receiver.nil?
          end

          # The keyword options of a column call, as `pair` nodes.
          def column_option_pairs(node)
            last = node.last_argument
            return [] unless last.respond_to?(:hash_type?) && last.hash_type?

            last.pairs.select { |pair| pair.key.sym_type? }
          end

          def column_option(node, name)
            column_option_pairs(node).find { |pair| pair.key.value == name }
          end

          def option_true?(node, name)
            column_option(node, name)&.value&.true_type? || false
          end

          # The argument carrying the new value: the third for the migration
          # form (`change_column_null :people, :email, false`), the second for
          # the block form (`t.change_null :email, false`). Nil when it was not
          # given — a trailing options hash does not count.
          def value_argument(node)
            argument = node.arguments[block_form?(node) ? 1 : 2]
            return if argument.nil?
            return if argument.respond_to?(:hash_type?) && argument.hash_type?

            argument
          end

          # Every `[ table, column ]` this call touches, as symbols. One pair per
          # name given; a reference contributes the `_id` column it really
          # creates, and a polymorphic one contributes `_type` as well.
          def column_identities(node)
            table = table_name(node)
            names = column_arguments(node).filter_map { |argument| literal_value(argument) }
            return [] if names.empty?

            names.flat_map { |name| columns_for(node, name) }
              .map { |column| [ table, column ] }
          end

          def columns_for(node, name)
            return [ name ] unless REFERENCE_TYPES.include?(node.method_name)

            columns = [ :"#{name}_id" ]
            columns << :"#{name}_type" if option_true?(node, :polymorphic)
            columns
          end

          # The arguments naming columns. The migration form names exactly one,
          # in second place; the block form names as many as it likes, up to the
          # first argument that is not a name.
          def column_arguments(node)
            return [ node.arguments[1] ].compact unless block_form?(node)
            return [ node.first_argument ].compact if SINGLE_NAME_BLOCK_SENDS.include?(node.method_name)

            node.arguments.take_while { |argument| argument.sym_type? || argument.str_type? }
          end

          # The migration form names its table; the block form takes it from the
          # enclosing `create_table` / `change_table`.
          def table_name(node)
            return literal_value(node.first_argument) unless block_form?(node)

            block = node.each_ancestor(:block).find do |ancestor|
              ancestor.send_node.receiver.nil? &&
                TABLE_BLOCKS.include?(ancestor.send_node.method_name)
            end

            literal_value(block.send_node.first_argument) if block
          end

          # True inside `def down`, a `dir.down { }` block, or the block of a
          # `drop_table`. Reversing a migration means restoring the previous
          # schema, so the rules that forbid going back are not the reverse
          # direction's business — and a `drop_table` block is nothing but the
          # definition the rollback will restore.
          def reversing?(node)
            return true if node.each_ancestor(:def).any? { |method| method.method?(:down) }

            node.each_ancestor(:block).any? do |ancestor|
              send = ancestor.send_node

              (send.method?(:down) && send.receiver&.lvar_type?) ||
                (send.method?(:drop_table) && send.receiver.nil?)
            end
          end

          # The `def up` / `def change` this call sits in, or the whole file when
          # it sits outside any method. Scopes a search to one direction so a
          # call in `down` cannot license one in `up`.
          def enclosing_body(node)
            node.each_ancestor(:def).first || processed_source.ast
          end

          # Calls of the given kind that follow `node` within its own method,
          # going the same direction. A promotion inside `dir.down { }` runs on
          # rollback and promotes nothing on the way forward.
          def later_sends_of_kind(node, kind)
            body = enclosing_body(node)
            return [] if body.nil?

            body.each_node(:send).select do |send|
              send.source_range.begin_pos > node.source_range.begin_pos &&
                column_send_kind(send) == kind &&
                !reversing?(send)
            end
          end

          def literal_value(node)
            node.value.to_sym if node.respond_to?(:value) && node.value.respond_to?(:to_sym)
          end
      end
    end
  end
end

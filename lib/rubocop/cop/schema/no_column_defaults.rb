# frozen_string_literal: true

module RuboCop
  module Cop
    module Schema
      # No column may carry a database default. `created_at` and `updated_at`
      # are the exception, so `t.timestamps` and `add_timestamps` are left
      # alone.
      #
      # A default in the schema is a second, invisible place where the domain
      # decides what a value should be. The model says one thing, the database
      # says another, and a row inserted outside the model gets the schema's
      # answer. Decide it once, in Ruby, where it can be read and tested.
      #
      # Removing a default is always allowed — that is this cop's own rule being
      # applied to an existing table. The reverse direction is exempt for the
      # same reason `NoNullableColumns` exempts it: `down` restores the previous
      # schema, defaults and all.
      #
      # @example
      #   # bad
      #   t.integer :attempts, null: false, default: 0
      #   change_column :people, :attempts, :integer, default: 0
      #   change_column_default :people, :attempts, from: nil, to: 0
      #   t.change_default :attempts, 0
      #
      #   # good
      #   t.integer :attempts, null: false
      #   t.timestamps
      #   change_column_default :people, :attempts, from: 0, to: nil
      #   t.change_default :attempts, nil
      class NoColumnDefaults < Base
        include ColumnDefinition

        MSG = "Remove `default:`. Defaults belong in the model, not in a " \
              "second invisible place where the schema decides."

        MSG_NEW_DEFAULT = "Do not give a column a database default. The model " \
                          "is the one place that should decide a value."

        RESTRICT_ON_SEND = COLUMN_SENDS

        def on_send(node)
          return if reversing?(node)

          case column_send_kind(node)
          when :create, :alter
            default = column_option(node, :default)
            add_offense(default) if default
          when :default_change
            add_offense(node, message: MSG_NEW_DEFAULT) unless removes_default?(node)
          end
        end

        private
          # `change_column_default :people, :x, from: 0, to: nil` and
          # `t.change_default :x, nil` both take a default away.
          def removes_default?(node)
            to = column_option(node, :to)
            return to.value.nil_type? if to

            value = value_argument(node)
            value.nil? || value.nil_type?
          end
      end
    end
  end
end

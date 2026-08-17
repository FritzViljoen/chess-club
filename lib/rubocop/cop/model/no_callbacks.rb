# frozen_string_literal: true

module RuboCop
  module Cop
    module Model
      # No model may register an Active Record lifecycle callback.
      #
      # A callback moves work away from the place that asked for it. `save`
      # reads like one thing and does several, and the extra ones are only
      # discoverable by reading the whole class. Order between them is
      # implicit, they fire for every writer including fixtures and backfills,
      # and testing the model in isolation stops being possible.
      #
      # Put the work in the object that wants it — a method that says what it
      # does, called where the decision is made.
      #
      # @example
      #   # bad
      #   class Person < ApplicationRecord
      #     before_save :normalize_email
      #     after_create_commit { Mailer.welcome(self).deliver_later }
      #   end
      #
      #   # good
      #   class Person < ApplicationRecord
      #     def normalize_email
      #       self.email = email.strip.downcase
      #     end
      #   end
      #
      #   # in the caller
      #   person.normalize_email
      #   person.save!
      #   Mailer.welcome(person).deliver_later
      class NoCallbacks < Base
        MSG = "Remove `%<callback>s`. A callback hides work behind `save`, " \
              "where the caller cannot see it. Call a named method instead."

        CALLBACKS = %i[
          after_commit
          after_create
          after_create_commit
          after_destroy
          after_destroy_commit
          after_find
          after_initialize
          after_rollback
          after_save
          after_save_commit
          after_touch
          after_update
          after_update_commit
          after_validation
          around_create
          around_destroy
          around_save
          around_update
          before_commit
          before_create
          before_destroy
          before_save
          before_update
          before_validation
        ].freeze

        RESTRICT_ON_SEND = CALLBACKS

        # Only the bare macro inside a class body registers a callback.
        # `Something.after_save` is someone else's method with the same name.
        def on_send(node)
          return if node.receiver

          add_offense(node.loc.selector,
            message: format(MSG, callback: node.method_name))
        end
      end
    end
  end
end

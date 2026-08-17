# frozen_string_literal: true

require "strscan"

module RuboCop
  module Cop
    module Vocabulary
      # No industry vocabulary in code.
      #
      # An industry noun in a name is the domain's word for a thing, not the
      # code's. It ties every reader to knowing the industry, it goes stale when
      # the industry renames itself, and it hides what the code actually does
      # with the thing. Name it for its role here; keep the industry's word in
      # data, where it can change without a deploy.
      #
      # The list lives in .rubocop.yml under `BannedTerms`, each term listed
      # with its plural. Matching is case-insensitive, so `widget`, `Widget` and
      # `WIDGET` are one entry — but `widgets` is its own, because a list that
      # inflects is a list nobody can read off the page.
      #
      # Source is split into words the way a name is read, not the way `\b`
      # reads it: on separators AND on case humps. `\bwidget\b` never matches
      # `widget_count` or `WidgetCount`, so a word-boundary rule silently misses
      # every compound spelling — which is the usual way a list like this ends
      # up reading as coverage it does not have. Here `widget_id`,
      # `spare_widget`, `WidgetCount` and `WIDGET_COUNT` all count, while
      # `widgetry` and `rewidgeted` do not.
      #
      # This looks at the whole source, comments and strings included: a banned
      # noun in a comment or a user-facing string is the same defect as one in
      # a class name.
      #
      # @example BannedTerms: [widget, widgets]
      #   # bad
      #   class Widget < ApplicationRecord
      #   def widget_count
      #   t.references :widget
      #   # every widget gets a score
      #
      #   # good
      #   class Part < ApplicationRecord
      #   def part_count
      #   t.references :part
      class BannedTerms < Base
        MSG = "`%<term>s` is industry vocabulary. Name it for what the code " \
              "does with it; the industry's word belongs in data."

        # One word as a name is read: an all-caps run (`WIDGET` in
        # `WIDGET_COUNT`), a capitalised word (`Widget` in `WidgetCount`), or a
        # lowercase run (`widget` in `spare_widget`). Separators are whatever is
        # left over, so `_`, punctuation and whitespace all end a word without
        # being named.
        WORD = /[A-Z]+(?![a-z])|[A-Z][a-z0-9]*|[a-z0-9]+/

        # Not `processed_source.blank?`: that is true whenever there is no AST,
        # and a file holding only comments has none — which is exactly a file
        # this cop still has something to say about.
        def on_new_investigation
          return if source.empty?

          terms = banned_terms
          return if terms.empty?

          each_word do |word, begin_pos|
            next unless terms.include?(word.downcase)

            add_offense(range_of(begin_pos, word.length), message: format(MSG, term: word))
          end
        end

        private
          # Listed in .rubocop.yml. No list means nothing to police — the cop
          # stays silent rather than inventing a vocabulary.
          def banned_terms
            Array(cop_config["BannedTerms"]).map { |term| term.to_s.downcase }
              .reject(&:empty?)
              .to_set
          end

          # The buffer's source, never `raw_source`: the buffer has collapsed
          # `\r\n` to `\n`, and offense ranges are positions into the buffer. A
          # CRLF file measured against `raw_source` reports every offense one
          # character further right per preceding line, eventually past the end
          # of the buffer entirely.
          def source
            processed_source.buffer.source
          end

          # Walks the source once, carrying the character offset forward rather
          # than searching from an index each time. `String#index` and slicing
          # both count characters from the start of the string on anything that
          # is not `ascii_only?`, so a single em-dash in a large file made the
          # obvious loop quadratic; `scan_until` returns the skipped text, whose
          # lengths sum to the length of the source.
          def each_word
            scanner = StringScanner.new(source)
            position = 0

            while (skipped = scanner.scan_until(WORD))
              word = scanner.matched
              position += skipped.length - word.length

              yield word, position

              position += word.length
            end
          end

          def range_of(begin_pos, length)
            Parser::Source::Range.new(processed_source.buffer, begin_pos, begin_pos + length)
          end
      end
    end
  end
end

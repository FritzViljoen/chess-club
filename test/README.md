# Tests

Minitest, the Rails default. `bin/rails test` runs them; `bin/ci` runs them along
with everything else the build runs.

## Where the weight goes

The ranking rules carry most of it. They are a plain object with no database
knowledge (constitution → `the-ranking-rules-live-in-one-object`), so the brief's
worked examples are written directly as tests, and the cases the brief leaves
ambiguous are named explicitly:

- both worked examples from the brief — a tie across five ranks, and the weaker
  member winning across six
- a tie between adjacent members, which changes nothing
- an adjacent win by the weaker member, which is a straight exchange
- the gap of two, where the brief contradicts itself
  ([`a-two-rank-gap-favours-the-winner`](../docs/decisions/a-two-rank-gap-favours-the-winner.md))
- games involving rank 1 and rank `n`
- the invariant: after every operation the ranks are still a permutation of `1..n`

Beyond that: model validations, appending a member at `n + 1`, closing the gap when
one is removed, the whole shuffle rolling back as one transaction, and request
tests for the standings, member CRUD and recording a game.

## A guard needs a test that proves it fires

Deleting a guard must turn a test red (principle →
`make-the-wrong-thing-impossible`). A test that passes whether or not the guard
exists is coverage in name only. This applies to the schema cops as much as to the
domain: each cop's tests assert both that it flags the bad form and that it accepts
the good one.

## Layout

- `test/lib/rubocop/` — the schema cops. `cop_case.rb` is the shared base; a
  subclass names its cop with `polices` and asserts on a fragment wrapped as a
  migration. See [`../lib/rubocop/README.md`](../lib/rubocop/README.md), including
  the `MigratedSchemaVersion` trap that makes a badly-named fixture invisible.
- `test/models/`, `test/controllers/` — the usual Rails places.

## Vocabulary

Tests use the same plain words as the code — `Game`, `tie`, `standings` — not the
vocabulary of the game
([`plain-words-in-code`](../docs/decisions/plain-words-in-code.md)). A test name
reading "the lower-ranked member wins" is preferred over one reading "an upset".

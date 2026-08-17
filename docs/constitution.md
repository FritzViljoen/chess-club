# Constitution

*The law. Below the [principles](principles.md), above the
[decisions](decisions/).*

> Each law names the principle it carries out and the guard that holds it. **A
> law with no guard says so** — an unenforced law is a convention, and calling it
> a law does not make it hold. A law that implements no principle is either a
> principle nobody has written down or a rule that should not be law.
>
> A decision may refine a law. None may contradict one: on conflict the
> constitution governs and the decision is corrected, or the constitution is
> amended by a decision that names the law it changes.

---

## `no-nullable-columns` — Every column is NOT NULL

No column in this schema may be nullable. If a value genuinely does not exist
for some rows, that is a missing table, not a missing value.

- **Principle:** `the-schema-states-the-invariant`
- **Guard:** `Schema/NoNullableColumns`, in
  [`lib/rubocop/cop/schema/`](../lib/rubocop/cop/schema/). Fails CI. Covers
  creation and alteration, resolves a reference to the column it really creates,
  and exempts the reverse direction.
- **Decision:** [`no-nullable-columns.md`](decisions/no-nullable-columns.md)

## `no-database-defaults` — No column carries a database default

`created_at` and `updated_at` excepted. A default in the schema is a second,
invisible place deciding a value; the model is the one place that decides.

- **Principle:** `the-schema-states-the-invariant`, `one-decision-one-place`
- **Guard:** `Schema/NoColumnDefaults`. Fails CI.
- **Decision:** [`no-database-defaults.md`](decisions/no-database-defaults.md)

## `a-nullable-column-lives-inside-one-migration` — A column may be nullable only between two statements of one method

A NOT NULL column cannot be added to a populated table in one statement. So a
column may be added nullable, filled, and promoted with `change_column_null` —
and the promotion must come later in the same method. A nullable column that
outlives its migration is what `no-nullable-columns` forbids.

- **Principle:** `the-schema-states-the-invariant`
- **Guard:** the promotion rule inside `Schema/NoNullableColumns`. Fails CI.
- **Decision:**
  [`a-nullable-column-lives-inside-one-migration.md`](decisions/a-nullable-column-lives-inside-one-migration.md)

## `no-lifecycle-callbacks` — No model registers an Active Record lifecycle callback

No `before_save`, `after_create`, `after_commit` or any of their siblings, in a
model or in a concern included into one. Work goes in a named method the caller
invokes.

- **Principle:** `one-decision-one-place`, `nothing-fails-quietly`
- **Guard:** `Model/NoCallbacks`, scoped to `app/models/**/*.rb`. Fails CI.
- **Decision:** [`no-lifecycle-callbacks.md`](decisions/no-lifecycle-callbacks.md)

## `ranks-are-a-dense-unique-sequence` — Ranks are exactly `1..n`, one member per rank

Every member holds a rank. No rank is shared, no rank is skipped, and the highest
rank is the number of members. Adding a member appends at `n + 1`; removing one
closes the gap.

- **Principle:** `the-schema-states-the-invariant`
- **Guard:** a unique index on `rank`, plus a test asserting the sequence is a
  permutation of `1..n` after every operation.
- **Decision:**
  [`ranks-are-a-dense-unique-sequence.md`](decisions/ranks-are-a-dense-unique-sequence.md)

## `a-game-is-recorded-in-one-transaction` — Recording a game is all-or-nothing

Persisting the game, applying every rank change and incrementing both players'
game counts happen in one transaction. A half-applied shuffle would leave the
standings in a state no rule allows.

- **Principle:** `nothing-fails-quietly`, `the-schema-states-the-invariant`
- **Guard:** a test that forces a failure mid-shuffle and asserts the standings
  are unchanged.

## `the-ranking-rules-live-in-one-object` — One object owns the ranking rules and knows nothing about storage

The rules that decide new ranks live in a single plain object. It takes the
current standings and a result, and returns the ranks that changed. It performs
no queries and holds no records, so it can be tested directly against the worked
examples.

- **Principle:** `one-decision-one-place`
- **Guard:** none that a machine can apply. A reviewer checks that no other file
  computes a rank.

## `ci-is-one-command` — CI runs exactly what a developer runs

The build runs `bin/ci` and nothing else. Its steps live in `config/ci.rb`, so a
green run locally means a green build, and there is no second list of checks to
drift.

- **Principle:** `one-way-to-say-each-thing`
- **Guard:** the workflow's only step is `bin/ci`.
- **Decision:** [`ci-is-one-command.md`](decisions/ci-is-one-command.md)

## `plain-words-in-code` — Identifiers use plain words

No industry term in a name: a contest is a `Game`, an equal result is a `tie`, the
ranked list is the `standings`. Binds identifiers, comments, tests and documents;
not a quotation of the brief.

- **Principle:** `no-industry-terms`
- **Guard:** none. This is a judgement a reviewer makes, and no check can make
  it.
- **Decision:** [`plain-words-in-code.md`](decisions/plain-words-in-code.md)

## `a-non-trivial-choice-is-a-decision-record` — A non-trivial choice gets a record, not a code comment

Where two defensible options existed, the reasoning goes in
[`decisions/`](decisions/) so the road not taken stays closed.

- **Principle:** `one-decision-one-place`
- **Guard:** none. Convention, held by review.
- **Decision:**
  [`decisions-are-named-not-numbered.md`](decisions/decisions-are-named-not-numbered.md)

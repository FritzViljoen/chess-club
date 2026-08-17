# a-contest-holds-results — A contest holds a collection of results, not two participant columns

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Principle:** `open-closed`, `single-responsibility`

## Context

The brief describes two people playing each other. The direct schema for that is
one table: `winner_id`, `loser_id` and an outcome, or `person_a_id`,
`person_b_id` and a result. Three columns, one row, no join.

The group it is built for does not only play in pairs. A round-robin afternoon
where six people are placed against each other is the same event with more
participants, and the brief says nothing about it.

## Decision

**`contests` holds when it happened. `contest_results` holds one row per
participant — who, and what place they finished in.**

A head-to-head contest is two rows. A tie is two rows sharing a `place`; there is
no outcome column and no draw flag.

**A validation requires exactly two results**, because the brief gives no rules
for more, and guessing them would be worse than refusing.

## Rationale

**A contest between two people and one between six differ only in how many rows
hang off them.** Naming the participants in columns writes "exactly two" into the
schema, where changing it costs a migration, a backfill, and an edit to
everything that reads those columns. As a collection, it costs a validation
(principle → `open-closed`).

**A tie needs no separate concept.** Equal places say it. An `outcome` column
would be a second way to express what `place` already holds, and the two could
disagree (principle → `one-way-to-say-each-thing`).

**`place` carries more than a winner flag.** A finishing order is what a
multi-participant event produces, so the column that supports two also supports
six without changing meaning.

**Refusing is honest.** The rules for a six-way contest are not derivable from
the brief's three cases — how the pairs combine, in what order, against which
starting positions. Inventing them would put a rule in the code that nobody
agreed to, which is worse than the validation that says so.

### Alternatives rejected

- **`winner_id` / `loser_id` / `tie` on one table.** Fewer moving parts and one
  fewer table. It hardcodes the participant count into column names, and a tie
  makes "winner" a lie.
- **A join table with no `place`, ordered by row id.** Order in a table is not a
  fact; it is an accident of insertion, and a correction would reorder it.
- **Modelling groups now.** No rules exist to model. See above.

## Trade-offs accepted

- **A table and a join for what is today always two rows.** Paid now, so that
  supporting more is not a migration later.
- **The two-participant rule lives in a validation, not the schema.** A unique
  index cannot express "exactly two", so the database would accept one row or
  three. `CalculateStandings` would then meet a contest it has no rule for.
- **Reading a contest costs a join.** At this size, nothing.

## Consequences

- `Contest#in_place_order` and `Contest#tie?` are how the outcome is read; nothing
  reads a winner column, because there is none.
- Supporting more than two participants changes one validation and the rule that
  folds a contest — no migration.
- The open question that remains is what those rules should be, and it is
  recorded in the spec rather than answered in code.

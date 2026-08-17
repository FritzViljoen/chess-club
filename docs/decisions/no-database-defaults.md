# no-database-defaults — No column carries a database default

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Enacts:** constitution → `no-database-defaults`
- **Related:** [`no-nullable-columns`](no-nullable-columns.md)

## Context

`t.integer :games_played, null: false, default: 0` is the ordinary way to give a
counter a starting value. It is also a second place that decides what a new
member's game count is. The model says one thing — or says nothing, and inherits
the schema's answer without saying so — and the database says another.

The two disagree the moment either changes. A model that starts new members at
zero and a column that defaults to zero are redundant until someone changes one
of them; then the answer depends on which path wrote the row.

## Decision

**No column carries a database default.** `created_at` and `updated_at` are the
exception: they are set by the framework, not by the domain, and `t.timestamps`
is left alone.

A cop, `Schema/NoColumnDefaults`, enforces this over `db/migrate` and fails CI.
Removing a default is always allowed — that is this rule being applied to an
existing table.

## Rationale

A default is invisible at the call site. Reading `Member.create!(name: "…")` tells
you nothing about what `games_played` will be; you have to go and read the
schema, and the schema is the one file nobody reads before writing a create.
Putting the value in the model puts it where the reader already is, and where a
test can assert it.

The rule also removes the escape hatch that would have quietly undermined
[`no-nullable-columns`](no-nullable-columns.md). Adding a NOT NULL column with a
default is the standard trick for a populated table, and it works — while
silently deciding a domain value in the schema. Closing both rules together
forces the honest form: add the column, fill it deliberately, promote it.

## Trade-offs accepted

- **Rows written outside the model need the value supplied.** Fixtures, seeds and
  console sessions must say what they mean. That is the intended cost.
- **A future bulk `insert_all` has to pass every column.** Acceptable; it also
  makes the write auditable at the call site.
- **Timestamps are inconsistent with the rule.** Deliberately. They are
  framework mechanics, and pretending otherwise would mean hand-setting two
  columns on every write to no benefit.

## Consequences

- The model is the only place a default value appears, so it is the only place to
  read or change one.
- The cop treats `change_column_default … to: nil` as removal and allows it, and
  exempts a migration's reverse direction, which must be free to restore what it
  removed.

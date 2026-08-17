# no-nullable-columns — Every column is NOT NULL

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Enacts:** constitution → `no-nullable-columns`
- **Related:** [`no-database-defaults`](no-database-defaults.md),
  [`a-nullable-column-lives-inside-one-migration`](a-nullable-column-lives-inside-one-migration.md)

## Context

Rails makes a nullable column the default: `t.string :email` produces a column
that accepts NULL. Nothing objects, and the ambiguity is free to introduce.

A nullable column collapses three different facts into one state. "No value has
been entered yet", "this does not apply to this row" and "the value was lost"
all read back as NULL, and no reader can tell them apart. So every call site
handles the nil, and each one guesses which of the three it means. Tony Hoare,
who introduced the null reference in ALGOL W in 1965, later called it his
billion-dollar mistake for precisely this reason.

## Decision

**No column in this schema may be nullable.** Every column is declared
`null: false`. Where a value genuinely does not exist for some rows, that is a
missing table, not a missing value — the rows that have the value go in their own
table with a foreign key.

A cop, `Schema/NoNullableColumns`, enforces this over `db/migrate` and fails CI.

## Rationale

The rule is worth having as a *guard* rather than a habit because the failure is
silent and late. A nullable column costs nothing on the day it is added; it costs
on the day some reader forgets the nil, in production, months later. A convention
cannot catch that. A build failure at the moment the migration is written can.

Enforcing it in the schema rather than the model matters too: a model validation
is advice to a form, while a NOT NULL column is a fact about the data. Anything
that writes outside the model — a console session, a fixture, a future import —
gets the constraint either way.

## Trade-offs accepted

- **More tables.** An optional attribute becomes a second table rather than a
  nullable column. That is the point — the nulls were marking a seam between two
  concepts sharing a row — but it is more schema than the lazy version.
- **Migrations against populated tables get longer.** Handled by
  [`a-nullable-column-lives-inside-one-migration`](a-nullable-column-lives-inside-one-migration.md).
- **`Rails/NotNullColumn` had to be disabled.** It wants a default alongside NOT
  NULL so the migration survives a populated table, which
  [`no-database-defaults`](no-database-defaults.md) forbids. The two rules are
  incompatible and this one wins.
- **The cop is our code to maintain.** No published cop does this, so there is a
  small amount of AST handling in `lib/rubocop/cop/schema/` with its own tests.

## Consequences

- Every model attribute is present. No `email.presence`, no `&.`, no "unknown"
  branch that exists only because the column allowed it.
- Engine-copied migrations are exempt; see
  [`engine-migrations-are-not-ours-to-edit`](engine-migrations-are-not-ours-to-edit.md).
- The cop covers alteration as well as creation, resolves a reference to the
  `_id` column it really creates, and exempts a migration's reverse direction —
  each of those is a hole a review found and closed.

# a-nullable-column-lives-inside-one-migration — A column may be nullable only between two statements of one method

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Enacts:** constitution → `a-nullable-column-lives-inside-one-migration`
- **Related:** [`no-nullable-columns`](no-nullable-columns.md),
  [`no-database-defaults`](no-database-defaults.md)

## Context

[`no-nullable-columns`](no-nullable-columns.md) and
[`no-database-defaults`](no-database-defaults.md) together make one ordinary
operation impossible as stated: adding a required column to a table that already
holds rows.

SQLite refuses it outright — `ALTER TABLE people ADD COLUMN email TEXT NOT NULL`
returns `Cannot add a NOT NULL column with default value NULL` as soon as the
table has a single row. (On an empty table it succeeds, which makes the failure
one you meet in production and not in development.) The two escapes are a
default, which is forbidden, and adding the column nullable, which is forbidden.

## Decision

**A column may be nullable only between two statements of the same method.** The
sanctioned form is three steps:

```ruby
add_column :people, :email, :string
Person.update_all(email: "")
change_column_null :people, :email, false
```

`Schema/NoNullableColumns` accepts a column with no `null: false` when a matching
`change_column_null … , false` appears **later in the same method**. Anything else
is an offense, and the message says which of the two problems it is.

## Rationale

Scoping to "later in the same method" is what makes the allowance safe rather
than a loophole. Three weaker versions were rejected in the course of getting
this right, each found by review:

- **Anywhere in the file** licenses a promotion sitting in `down`, which promotes
  nothing in `up`. The column ships nullable and the cop is silent.
- **Anywhere in the method, any order** licenses a promotion written above the
  `add_column`, which runs before the column exists.
- **Matching on column name alone** licenses a promotion of the same name on
  another table.

The remaining gap is a promotion inside a conditional that never runs
(`if false`). It is accepted: no author writes that except to defeat the cop, and
anyone willing to do that has `rubocop:disable` available anyway.

A reference needed special handling. `add_reference :people, :club` creates
`club_id`, so the promotion must name `club_id` — the cop resolves the identity to
the column that really exists, and a polymorphic reference requires both `_id`
and `_type` to be promoted.

## Trade-offs accepted

- **The fill step is unchecked.** Nothing verifies that `update_all` sets a
  sensible value, or that it runs before the promotion at all. The promotion will
  fail loudly at migrate time if rows are still NULL, which is the guard that
  matters.
- **Three lines instead of one.** The verbosity is the point: each step is a
  decision the author has to make on purpose.
- **`up`/`down` pairs are needed more often.** `change` cannot always reverse a
  promotion, so some migrations become explicit. The cop exempts the reverse
  direction so those are writable.

## Consequences

- No nullable column survives a migration, so
  [`no-nullable-columns`](no-nullable-columns.md) holds in the schema even though
  it is briefly violated in flight.
- The cop's tests carry each rejected variant above as a case, so the loopholes
  stay closed.

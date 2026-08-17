# engine-migrations-are-not-ours-to-edit — House rules do not apply to migrations copied in from an engine

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Related:** [`no-nullable-columns`](no-nullable-columns.md),
  [`no-database-defaults`](no-database-defaults.md)

## Context

`bin/rails active_storage:install` copies a migration into `db/migrate` named
`…_create_active_storage_tables.active_storage.rb`. It lands in our tree, it is
matched by `db/migrate/*.rb`, and it is full of nullable columns and defaults.

It is also not ours. Editing it to satisfy a house rule means diverging from the
engine, and the next `rails … :install` or engine upgrade overwrites or conflicts
with the edit. The alternative — leaving it — means CI is red from the moment any
engine is installed, permanently, for a reason nobody can fix.

## Decision

**Migrations copied in from an engine are excluded from the schema cops.** The
exclusion is `db/migrate/*.*.rb`, which matches the dotted suffix Rails gives to
every copied migration and nothing we write ourselves.

## Rationale

The dotted filename is a reliable marker because Rails generates it: `install`
appends `.<engine_name>` before `.rb` precisely to record where the migration
came from. Our own migrations, generated or hand-written, never carry a second
dot.

Excluding by filename rather than by content also keeps the rule legible. "If it
came from an engine, it is out of scope" is a sentence a reader can check against
a directory listing. A content-based exemption — "unless the table name starts
with `active_storage_`" — would need extending for every future engine and would
quietly grant exemptions to our own tables that happened to match.

## Trade-offs accepted

- **The exemption is broad.** Anything with a dotted name is exempt, including a
  file someone names that way deliberately. Accepted: doing so is a conspicuous
  act, and `rubocop:disable` is easier.
- **Engine tables end up with nullable columns in our schema.** True, and outside
  our control. The rule constrains the tables we design.
- **No engine is installed yet.** The exclusion is therefore unexercised in
  production, though it is covered by a test and was verified against the real
  Active Storage migration.

## Consequences

- Installing an engine does not turn the build red.
- The exclusion appears twice in `.rubocop.yml`, once per cop. RuboCop rejects
  the YAML anchor that would let it appear once, so the duplication stands.

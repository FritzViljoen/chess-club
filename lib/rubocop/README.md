# Schema cops

House RuboCop cops that hold the schema laws. Two of them, both over
`db/migrate`, both failing CI.

| Cop | Law |
|---|---|
| `Schema/NoNullableColumns` | constitution → `no-nullable-columns`, `a-nullable-column-lives-inside-one-migration` |
| `Schema/NoColumnDefaults` | constitution → `no-database-defaults` |

Each cop's own file carries the full rule and its examples. Start there;
[`../../docs/decisions/no-nullable-columns.md`](../../docs/decisions/no-nullable-columns.md)
and [`no-database-defaults.md`](../../docs/decisions/no-database-defaults.md) carry
the reasoning.

## Layout

- `schema.rb` — the loader. `.rubocop.yml` requires this one file; it requires the
  shared module and then globs the cops, so a new cop needs no config change.
- `cop/schema/column_definition.rb` — shared recognition of the migration calls
  that decide nullability or a default. Both cops include it.
- `cop/schema/*.rb` — one cop per file.

The namespace is `Schema`, not the app's name: these rules are about schemas and
nothing about this club (constitution → `plain-words-in-code`).

## What the shared module knows

Every relevant migration call is one of five kinds — a column is created, a column
is redefined, only its nullability changes, only its default changes, or it is
`timestamps`. Each kind comes in two forms, called on the table object inside a
`create_table` / `change_table` block or called on the migration itself. The module
classifies a call, extracts its options, resolves the `[ table, column ]` it
touches, and answers whether the call sits in a migration's reverse direction.

Three of those are less obvious than they sound, and each exists because a review
found a hole:

- **A reference names an association, not a column.** `add_reference :members,
  :club` creates `club_id`, so identity resolves to `club_id` — and to
  `club_type` as well when the reference is polymorphic.
- **The reverse direction is exempt.** `down` restores the previous schema, which
  is the state these cops forbid. Without the exemption a reversible migration
  cannot be written.
- **Scope is the enclosing method, in source order.** A promotion in `down` must
  not license a nullable column in `up`, and one written above the `add_column`
  must not license the column below it.

## Tests

`test/lib/rubocop/`. `cop_case.rb` is the shared base: a subclass names its cop
with `polices`, then asserts on a fragment wrapped as a migration.

One trap worth knowing. rubocop-rails silently skips offenses in any migration
whose timestamp is at or below `AllCops: MigratedSchemaVersion`, which defaults to
the UNIX epoch, `19700101000000`. A test fixture or probe migration named with
that exact timestamp is invisible to every cop and looks like a passing file. The
test base class uses a plausible timestamp for this reason.

## Not loaded by the app

`lib/rubocop` is excluded from `config.autoload_lib`. The cops live under the
`RuboCop` namespace, which Zeitwerk reads as `Rubocop` and refuses to load, and
they have no business inside the running app in any case.

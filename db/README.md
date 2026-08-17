# Database

SQLite. One file, no services to start — clone and `bin/setup`.

## The rules that bind a migration

Two of them, both enforced by cops in
[`../lib/rubocop/`](../lib/rubocop/README.md), both failing CI:

- **Every column is `null: false`** (constitution → `no-nullable-columns`). If a
  value genuinely does not exist for some rows, that is a missing table, not a
  missing value.
- **No column carries a `default:`** (constitution → `no-database-defaults`).
  `created_at` and `updated_at` excepted; `t.timestamps` handles those.

## Adding a required column to a table that already has rows

This cannot be done in one statement — SQLite answers `Cannot add a NOT NULL
column with default value NULL` — and the usual escape, a default, is forbidden.
The sanctioned form is three steps in the same method, in this order:

```ruby
add_column :members, :email, :string
Member.update_all(email: "")
change_column_null :members, :email, false
```

The promotion has to come **later in the same method**. A promotion in `down`
promotes nothing in `up`, and one written above the `add_column` runs before the
column exists — the cop rejects both
(constitution → `a-nullable-column-lives-inside-one-migration`).

For a reference, promote the column that actually exists: `add_reference :members,
:club` creates `club_id`, so the promotion names `club_id`. A polymorphic reference
needs `club_id` and `club_type` both promoted.

## Reversing

`down` is exempt from both cops. Restoring a nullable column or putting a default
back is what reversing means, so a reversible `up`/`down` pair is writable as
normal.

## Migrations from an engine

Anything Rails copies in — `…_create_active_storage_tables.active_storage.rb` and
the like — is excluded from the cops by its dotted filename. Those files are not
ours to edit
([`engine-migrations-are-not-ours-to-edit`](../docs/decisions/engine-migrations-are-not-ours-to-edit.md)).

## The rank column

`members.rank` carries a unique index, and the set of ranks is always a permutation
of `1..n` (constitution → `ranks-are-a-dense-unique-sequence`). Because of the
index, a shuffle cannot write the new ranks in one pass — an intermediate state
would collide — so it writes in two passes inside one transaction.

## Seeds

`seeds.rb` is exercised by CI: `bin/ci` runs `db:seed:replant` against the test
database, so seeds that stop working break the build rather than rotting quietly.

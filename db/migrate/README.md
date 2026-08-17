# db/migrate

Migrations. Three cops in [`../../lib/rubocop/`](../../lib/rubocop/README.md) bind
every one of them and all three fail CI: the two schema rules below, and
`Vocabulary/BannedTerms`, which covers `db/**/*.rb` and rejects any industry term in
the list in `.rubocop.yml`. **Read that list before naming a table or a column** —
the examples below use deliberately neutral names for that reason.

## True of every migration here

**Every column is `null: false`** (constitution → `no-nullable-columns`). Where a
value genuinely does not exist for some rows, that is a missing table, not a missing
value.

**No column carries a `default:`** (constitution → `no-database-defaults`).
`t.timestamps` and `add_timestamps` are the exception; every other starting value is
decided in the model.

**A required column on a populated table takes three steps, in one method, in this
order** (constitution → `a-nullable-column-lives-inside-one-migration`):

```ruby
add_column :people, :email, :string
Person.update_all(email: "")
change_column_null :people, :email, false
```

The promotion must come *later in the same method*. One in `down` promotes nothing
on the way forward; one written above the `add_column` runs before the column
exists. Promote the column that really exists — `add_reference :people, :organisation`
creates `organisation_id`, and a polymorphic reference creates `organisation_type` too.

**The reverse direction is exempt from both rules.** Restoring a nullable column or
putting a default back is what reversing means, so `down` may do either and a
reversible `up`/`down` pair is written as normal.

**A file with a dotted name is not ours.**
`…_create_active_storage_tables.active_storage.rb` and its like are copied in by an
engine and excluded from the cops: editing one diverges from the engine, and leaving
it unexcluded would keep the build red forever.

**A timestamp at or below `19700101000000` disables every cop for that file.** That
is rubocop-rails' "already migrated" sentinel. A migration named that way reads as a
clean pass while being checked by nothing.

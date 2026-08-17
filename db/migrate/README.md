# db/migrate

Migrations. Two house rules bind every one of them, both enforced by cops in
[`../../lib/rubocop/`](../../lib/rubocop/README.md), both failing CI.

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
add_column :members, :email, :string
Member.update_all(email: "")
change_column_null :members, :email, false
```

The promotion must come *later in the same method*. One in `down` promotes nothing
on the way forward; one written above the `add_column` runs before the column
exists. Promote the column that really exists — `add_reference :members, :club`
creates `club_id`, and a polymorphic reference creates `club_type` too.

**The reverse direction is exempt from both rules.** Restoring a nullable column or
putting a default back is what reversing means, so `down` may do either and a
reversible `up`/`down` pair is written as normal.

**A file with a dotted name is not ours.**
`…_create_active_storage_tables.active_storage.rb` and its like are copied in by an
engine and excluded from the cops: editing one diverges from the engine, and leaving
it unexcluded would keep the build red forever
([`engine-migrations-are-not-ours-to-edit`](../../docs/decisions/engine-migrations-are-not-ours-to-edit.md)).

**A timestamp at or below `19700101000000` disables every cop for that file.** That
is rubocop-rails' "already migrated" sentinel. A migration named that way reads as a
clean pass while being checked by nothing.

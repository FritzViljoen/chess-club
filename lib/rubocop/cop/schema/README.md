# lib/rubocop/cop/schema

Cops that police the database schema. Each is scoped to `db/migrate` and fails CI.
The rules they hold are in [`../../../../db/migrate/README.md`](../../../../db/migrate/README.md);
what each cop forbids is at the top of its own file.

## True of every file here

**`column_definition.rb` is the shared module and every cop includes it.** It
classifies a migration call, reads its options, resolves the `[ table, column ]`
pairs it touches, and answers whether the call sits in a migration's reverse
direction. A cop here asks the module rather than parsing arguments itself
(principle → `one-decision-one-place`).

**Both forms of every call are recognised** — on the table object inside a
`create_table` / `change_table` block, and on the migration itself. A cop that
handles one form and not the other has a hole in it.

**The reverse direction is exempt.** `down`, `dir.down { }` and a `drop_table` block
describe the schema a rollback restores, which is the state these cops forbid.
Without the exemption a reversible migration cannot be written.

**A search across a file is scoped to the enclosing method and to source order.**
A call in `down` must not license one in `up`, and one written above must not license
what appears below it.

**A test fixture needs a plausible migration timestamp.** rubocop-rails skips every
offense in a file timestamped at or below `AllCops: MigratedSchemaVersion` — the UNIX
epoch by default — so a fixture named `19700101000000_…` reads as a clean pass while
being checked by nothing.

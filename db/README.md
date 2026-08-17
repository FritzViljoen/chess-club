# db

The database: the migrations that build it, the schema they produce, and the seeds.
SQLite — one file, no services to start.

The rules that bind a migration are in
[`migrate/README.md`](migrate/README.md).

## True of every file here

**`schema.rb` is generated. Never hand-edit it.** It is the output of running the
migrations, so a change made here is lost the next time they run. To change the
schema, write a migration.

**Everything in this folder is checked in except the database file itself.** The
`.sqlite3` files are ignored; migrations, `schema.rb` and `seeds.rb` are reviewed
like any other code.

**An invariant belongs in the schema.** If a value must be unique, the index is
unique; if it must exist, the column is NOT NULL. A model validation cannot see a
concurrent write (principle → `the-schema-states-the-invariant`).

**`bin/ci` exercises this folder.** It prepares the database and runs
`db:seed:replant`, so a broken migration or broken seeds break the build rather
than rotting quietly.

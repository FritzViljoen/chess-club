# app/models

Records, and the rules that belong to a single record. Also the plain objects the
domain passes around: `Page`, `Ladder`, `Standing`, `Listing`, `SearchTerm`.

## True of every file here

**A default value is decided here.** No column carries a database default
(constitution → `no-database-defaults`).

**No attribute is ever absent.** No column is nullable
(constitution → `no-nullable-columns`), so a `&.` or an "unknown" branch means
the schema or the code is wrong.

**A validation is not the invariant.** What makes a rule true is the constraint
in the schema (principle → `the-schema-states-the-invariant`).

**A rule shared by more than one caller does not live here.** A model holds what
is true of one record (principle → `one-decision-one-place`).

**No lifecycle callback, ever** — and no `dependent:` on an association, which is
the same thing in different clothes: `contest.destroy` should read as one delete
and do one. The service that decided to delete says what else goes
(constitution → `no-lifecycle-callbacks`, guarded by `Model/NoCallbacks`).

**A plain object asserts its arguments too**, at construction, like a service.

# app/services

Every operation the application performs. One service, one operation, one public
method — `call`.

## True of every file here

**Every argument is type-checked in a hand-written `initialize`, and nowhere
else** (constitution → `arguments-are-typed-at-construction`). Past that line
nothing re-checks: a failure at the guard is the caller's defect, a failure after
it is this service's.

**A time argument carries its zone** — `ActiveSupport::TimeWithZone`, never
`Time` or `DateTime` (constitution → `a-time-names-its-zone`).

**`call` answers with the thing itself** — the record it wrote, the rows it read
(constitution → `a-service-answers-with-what-it-made`). A write answers with its
record and `record.errors.none?` says whether it was accepted.

**Reading and writing are separate services**, told apart by their names and by
what they do — never by a flag.

**A change that spans records is one transaction.** Note that `return` from
inside a transaction block COMMITS it; abandon work with
`raise ActiveRecord::Rollback`.

**Nothing here knows about HTTP.** No params, no session, no rendering.

# email-identifies-a-person — Email is how a person is identified, so it is required and unique

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Principle:** `the-schema-states-the-invariant`, `one-way-to-say-each-thing`

## Context

People need an identifier the outside world can use. `id` is not one: it is this
database's own counter, it means nothing to anybody who does not have the
database, and it cannot be quoted between two people talking about the same
member. The brief describes no number of any kind — no card, no roll, no
reference — so nothing exists to adopt.

An earlier ruling in the same design made email **optional**: `''` rather than
`NULL`, with a partial unique index `WHERE email != ''` so that a second person
without one was still allowed. That is coherent as long as email is only contact
detail. It stops being coherent the moment email is the identifier, because an
identifier that half the rows do not have identifies nothing.

## Decision

**Email is required and unique, and it is how a person is identified from
outside.** The unique index is what makes that true; the validation is advice to
the form.

**URLs stay on `id`.** `/people/12`, not `/people/ann%40example.test`.

## Rationale

**An identifier cannot be optional.** The partial index existed to let blanks
repeat. Once the column identifies somebody, a blank is a row that cannot be
named and two blanks are two rows that cannot be told apart.

**The index, not the validation.** A uniqueness validation loses a race between
two requests; the index refuses the second write whatever order they arrive in
(principle → `the-schema-states-the-invariant`).

**`id` in URLs, because an address gets corrected.** Putting the identifier in
the path means every link to a person breaks the day they change providers, and
puts the address into logs, browser history and referrer headers. An identifier
people quote to each other and a key that addresses a row are different jobs;
this is one of the few places where two ways to say a thing is right, and each is
used for exactly one purpose.

### Alternatives rejected

- **A membership number.** The obvious identifier, and the brief describes none.
  Inventing one is inventing a business rule nobody asked for.
- **Keep email optional and identify by `id`.** Honest, but leaves the group with
  no way to name a person outside the application.
- **Email as the URL parameter.** Reads as identity all the way through, and
  breaks every existing link on a correction.

## Trade-offs accepted

- **Somebody without an email cannot be added.** For a group that already
  communicates by email this is a fair floor; for one that does not, this
  decision is the thing to revisit, not the schema.
- **Changing an address rewrites the identifier.** No history of the old one is
  kept. Nothing in this application refers back to it, so nothing breaks — but a
  future audit trail would need one.
- **Two identifiers exist.** `id` addresses the row, email names the person.
  Justified above, and it is the sort of thing `one-way-to-say-each-thing` would
  otherwise refuse.

## Consequences

- `Person` validates email for presence and uniqueness; the migration carries a
  plain unique index rather than a partial one.
- The design document was corrected rather than the code, because this decision
  changes the intended shape (constitution → `documents-state-the-intended-shape`).
- The members form marks email required and says what it is for.

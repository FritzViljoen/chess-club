# a-service-returns-a-result — Every service answers with a result

> **Superseded on 2026-08-17** by
> [`a-service-answers-with-what-it-made`](a-service-answers-with-what-it-made.md).
> Left in place because the reasoning below is still correct about Ruby, and the
> superseding record says exactly when it would be right to come back to it.

- **Status:** Superseded by [`a-service-answers-with-what-it-made`](a-service-answers-with-what-it-made.md)
- **Date:** 2026-08-17
- **Deciders:** FV
- **Enacts:** constitution → `a-service-returns-a-result`

## Context

An operation can fail in two unrelated ways. It can fail because the world says
no — the round is already archived, the place is taken — which is an answer the
caller has to render. It can also fail because the code is wrong, which is not an
answer at all.

Ruby's default makes the two indistinguishable. A method returns whatever its
last line evaluated to: an operation ending in `record.save` returns `true` or
`false`, one ending in `update!` returns the record, one ending in a guard clause
returns `nil`. The caller cannot tell any of them from a deliberate answer.

There is a second question underneath: how many kinds of operation there are.
A well-known split gives writing and reading their own base classes and their own
names. This is a small application.

## Decision

**One base — `Service` — and every service returns a `Result`.**
`success(value)` when the work was done, `failure(:code)` for a refusal the
caller can handle. `Service.call` checks the return value and raises `TypeError`
on anything else.

**A service that reads answers `success(rows)`**, the same shape as one that
writes.

**Reading and writing are still separate services**, told apart by their names
and by what they do — not by two base classes, and never by a flag inside one
service.

## Rationale

**The check has to be at the seam, or it is not a check.** `Service.call` is the
one door every service is entered through, so it is where the shape of the answer
can be enforced. Without it, "returns a Result" is a convention, and the first
service that ends in `save` breaks it silently for its caller.

**A code, not a sentence.** `failure(:already_archived)` leaves the wording to
whatever renders it — a page, a JSON body, a log line. A service returning a
message would be deciding presentation from inside the domain.

**A refusal is not an exception.** Raising for "the round is already archived"
means every caller wraps the call in a rescue, and that rescue is where the real
defect gets swallowed too (principle → `nothing-fails-quietly`).

**One shape, because two would have to be told apart.** If reads returned raw
data and writes returned a `Result`, every caller would need to know which kind
it was holding, and every service that changed category would break its callers
silently. One way to say each thing is worth an `.value` on a read
(principle → `one-way-to-say-each-thing`).

**One folder, because the split is real but not structural.** Reading and writing
genuinely are different operations, and they get different classes. What they do
not need is separate base classes, separate folders and a pair of borrowed names
to go with them: that is architecture for an application several times this size,
and the vocabulary would have to be explained to every reader
(principle → `no-industry-terms`).

### Alternatives rejected

- **Separate `Command` and `Query` bases.** The split this project actually needs
  is one operation per class, which one base gives. The rest is ceremony and a
  pair of terms of art, and it can be introduced later if reads and writes ever
  need to differ in more than their names.
- **Return the record, raise on failure.** The Rails default: every expected
  refusal becomes an exception and every caller becomes a rescuer.
- **Return true/false and expose `errors` on the service.** Two calls to learn one
  thing, and the object has to stay alive between them.
- **A gem — dry-monads, Interactor, an `Either`.** More vocabulary than this app
  has questions. `Result` is a Struct with three methods and no dependency.
- **A separate object per record — an immutable, value-compared "entity" with its
  own validity.** Worth having when data travels between layers without a record
  behind it; today every value either comes off a model or is passed as a
  primitive, so it would be a base class with no subclasses.

## Trade-offs accepted

- **A caller has to unwrap.** `result.success?` then `result.value` — and a read
  pays that price for a refusal it may never have. Deliberate: it is the point
  where a refusal has to be dealt with, and one shape is worth more than the
  saved call.
- **`Result` carries no message.** Anything wanting words maps the code, where the
  words are chosen.
- **The check is at runtime, not in CI.** A service returning the wrong thing is
  caught by its first call, which its own test is. No cop can see what an
  arbitrary `call` returns.
- **Nothing enforces that a reading service does not write.** One base cannot tell
  them apart; that is what review is for.

## Consequences

- A caller reads `success?` without first checking what it was handed.
- A refusal and a defect never arrive as the same thing.
- `app/services/` holds every operation. A rule two callers need lives there, not
  in a model and not in an action.

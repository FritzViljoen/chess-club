# a-service-answers-with-what-it-made — Every service answers with the thing itself, not an envelope holding it

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Supersedes:** [`a-service-returns-a-result`](a-service-returns-a-result.md)
- **Enacts:** constitution → `a-service-answers-with-what-it-made`
- **Principle:** `one-way-to-say-each-thing`

## Context

The superseded decision had every service return a `Result` — `success(value)` or
`failure(:code)` — with `Service.call` raising `TypeError` on anything else. Its
reasoning was sound and is worth reading: Ruby returns whatever the last line
evaluated to, so an operation ending in `record.save` hands back `true`, one
ending in `update!` hands back the record, and one ending in a guard clause hands
back `nil`. The caller cannot tell any of them from a deliberate answer.

Built out across ten services, the envelope did not pay for itself here.

**Every caller unwrapped, and none of them branched.** Of the reads, all three
were `ReadPeople.call(…).value` with no check — because a read has no refusal,
which the original decision says itself ("an empty answer is an answer"). The
`.value` was pure ceremony at every call site.

**The writes had exactly one refusal between them, `:invalid`**, and it meant
"the record did not validate" — which the record already knew. The code was a
second vocabulary that had to be kept in step with the validations, and the
caller re-rendering the form needed the record anyway. That pressure showed:
`Result` grew a third constructor, `refusal(value, code)`, carrying both a value
and an error, which the base class had documented as impossible.

**The guard checked the wrapper, not the answer.** `Service.call` raised on a
return that was not a `Result` — it could never check that the value inside was
the right one. The law's own text admitted the limit.

## Decision

**A service answers with the thing it made, found or worked out.** A record, a
page of rows, an ordered list. No envelope, no unwrapping.

**A write answers with its record, and the record says whether it was
accepted:** `record.errors.none?`.

**A defect raises**, as before. `typed` raises on a caller's mistake; `destroy!`
raises on a broken invariant. Nothing rescues either into a value.

**Reading and writing stay separate services**, told apart by their names and by
what they do — unchanged from the superseded decision, and still not negotiable.

## Rationale

**One question, both cases.** `errors.none?` is the same check after a create and
after an update. The `Result` needed `persisted?`-shaped thinking for one and a
code for the other, which is the "two ways to say each thing" this house calls
the defect.

**The record is the thing the caller wants.** Every refusal in this application
ends in a re-rendered form, and a form binds to a record. Handing back a code and
making the caller find the record again was work in service of a shape.

**The brief asks for a simple application.** Ten services and a Struct with three
constructors, where the Rails idiom is a record that carries its own errors, is
ceremony a reviewer would rightly ask about — and the answer would have been "so
that refusals are distinguishable", for a codebase with one refusal.

### What is given up, and why it is acceptable here

The superseded decision's central claim is true: Ruby's default return makes a
`nil` from a guard clause indistinguishable from a deliberate answer. That risk
is real and is now unguarded.

It is acceptable **at this size**: ten services, each with one caller and its own
test, in an application with one refusal. It stops being acceptable when a
service grows several refusals a caller must tell apart — at which point the
right move is to bring the envelope back for that service, not to invent a
second, weaker signal.

### Alternatives rejected

- **Keep `Result` and drop only `refusal`.** Leaves every read unwrapping for a
  refusal it cannot have.
- **Return the record but keep a `Result` for reads.** Two shapes, so every
  caller must know which kind it is holding — precisely what the original
  decision rejected, and rightly.
- **Raise on a refused write.** Makes every caller a rescuer and swallows real
  defects in the same clause.

## Trade-offs accepted

- **Nothing checks what a service returns.** The `TypeError` is gone; a service
  that ends in `save` and returns `true` is caught by its own test or not at all.
- **A refusal is no longer a named code.** `errors` is a bag of messages, not a
  closed set, so a caller cannot switch on the reason. No caller does.
- **The superseded decision's reasoning is now only in that record.** It is left
  in place, marked superseded, because the road it closed is worth keeping closed
  until the conditions above change.

## Consequences

- `Service` is a base class with one method: `call` constructs and calls.
- `app/services/README.md` states what a service answers with and how a caller
  asks whether a write was accepted.
- The `Result` struct, `success`, `failure` and `refusal` are gone.

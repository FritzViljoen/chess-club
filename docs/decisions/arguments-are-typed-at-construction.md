# arguments-are-typed-at-construction — Every argument of a service is type-checked where it arrives

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Enacts:** constitution → `arguments-are-typed-at-construction`

## Context

Ruby will hand any object to any method. A `Date` and the string `"2026-08-17"`
are interchangeable right up to the first comparison, and a `nil` is
interchangeable with everything until something is called on it. The failure
surfaces far from the caller that caused it: a comparison that quietly answers
false, a query that finds nothing, a row saved with a blank in it.

The objects most exposed to this are the ones with the most callers — the
services a controller, a job and a test all construct.

## Decision

**Every `Service` takes its arguments as keywords in a hand-written
`initialize`, and passes each one through a `TypedArguments` guard.**

```ruby
def initialize(round:, on:)
  @round = typed(round, Round)
  @on = typed(on, Date)
end
```

`typed` asserts and never coerces. `nil` is a mismatch like any other, and
`allow_nil: true` is how a caller says otherwise, spelled out where it applies.
A collection is asserted with `typed_array` or `typed_hash`, which check the
collection and then every element. `Service/NoUnguardedArguments` fails CI on a keyword
no guard covers.

## Rationale

**A mismatch is a defect, so it raises.** Not a validation failure, not a
rendered message — a caller passed the wrong thing, and the loudest possible
failure at the earliest possible moment is what gets it fixed. `ArgumentError`
is the class Ruby already raises for a missing or unknown keyword, so every bad
argument to a service arrives as one error class.

**The boundary is what pays.** Inside the service every value is already right,
so nothing there re-checks one. The defensive code does not move to the top — it
stops existing, replaced by an assertion per argument.

**And a failure gets a side.** A raise at the guard is the caller's defect; a
failure past it is the service's own. Without the line, settling which of the two
a bug is means reading both objects together.

**Types and rules are different failures with different audiences.** "This is not
a Date" is for the developer and raises. "This date is before the round opened"
is for the requester, and is reported — the service returns `failure(:code)` and
the caller renders it. Collapsing the two either raises at a person
who typed something reasonable, or swallows a defect as a form error.

**Asserting is not parsing.** Turning `"2026-08-17"` into a Date is the seam's
job (`untrusted-input-is-parsed-at-the-seam`). If the guard coerced, every
operation would become a second parser, with its own answer for bad input.

**Written, not generated.** A macro — `argument :on, Date` — would build the
initializer behind the class. The assignment would stop being visible, `typed(on,
Date)` would stop being greppable, and the shape of the object would depend on
knowing the macro.

### Alternatives rejected

- **Sorbet or RBS.** Real static typing, checked before the code runs, and a far
  larger commitment: a second language, a build step, and gradual-typing
  boundaries to reason about. Reconsider when the app is big enough to earn it.
- **Duck typing — `respond_to?(:starts_on)`.** Asserts a method name, not a type:
  everything in the system that answers that name passes. It also invites taking
  a whole record to read one field off it, which is the coupling
  `interface-segregation` exists to prevent.
- **Validations only, no type check.** Leaves "wrong type" and "invalid data" as
  one failure, and defers both to whoever eventually calls `valid?` on a record.
- **Nothing at all, held by review.** The rule that is remembered rather than
  checked is the rule that is missing from the initializer written at 6pm
  (principle → `make-the-wrong-thing-impossible`).

## Trade-offs accepted

- **A line per argument.** Deliberately: the line says what the argument is, and
  the class reads as ordinary Ruby.
- **One type per argument.** A union would push "which one did I get?" branching
  into the body. Where alternatives are genuine, they get a shared ancestor
  (`Numeric`) or a marker (`Boolean`).
- **The guard cannot check the type is the right one.** `typed(on, String)` where
  a Date was meant passes. Review catches that; the cop only ensures something
  was asserted.
- **A service may only take named keywords.** `*args`, `**options`, `(...)` and a
  positional Hash are all offenses, because none of them can be guarded by name.
  Every input is spelled out, which is the point and also the cost.
- **Callers must convert before they call.** Which is the point, and is why the
  seam has parsers.

## Consequences

- A service either has the values it says it has, or it never existed.
- The seam parses, the service asserts, and neither does the other's job.
- `Boolean` exists so a flag argument can name one type.

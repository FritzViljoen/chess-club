# Principles

*How the code is built. Above every other document — we **follow** these; the law
below them is what we **obey**.*

> **Layer 1.** These decide what shape the code takes. Everything else descends
> from them: the [constitution](constitution.md) states the laws that carry them
> out, and the [decisions](decisions/) enact those laws in specific cases.
>
> **Nothing checks a principle, and nothing can.** "Is this one concern or
> three?" is a judgement, not a predicate. What is checkable is the *law* a
> principle produces, so every guard is named in the constitution beside the law
> it holds, and never here.

---

### `the-schema-states-the-invariant` — The schema states the invariant, not the model alone

A rule the database does not know is a rule the database will break. If a value
must exist, the column is NOT NULL; if a rank must be unique, the index is
unique. A validation in the model is a courtesy to the user; the constraint is
what makes the rule true. Nulls in particular are ambiguity written into
storage — "no value yet", "not applicable" and "we lost it" become one state
that every reader has to disambiguate and none can.

### `one-decision-one-place` — One decision has one home, reachable from every caller

A rule a caller cannot reach gets copied. So a rule lives where every caller can
call it, and unreachability is a structural defect to fix, not a licence to
restate the rule locally under a comment promising to keep it in sync. One object
owns a decision, it knows nothing about the database, and every caller goes
through it.

### `make-the-wrong-thing-impossible` — Make the wrong thing impossible, not merely forbidden

A convention is a promise someone has to remember; a failing build is not. When
a rule matters, encode it — a unique index, a NOT NULL column, a cop that fails
CI. And every guard needs a test that proves it fires: delete the guard, watch
the test go red, or the guard reads as coverage while catching nothing.

### `nothing-fails-quietly` — Nothing fails quietly

An operation either completes or says why it did not. A rank shuffle that half
applies is worse than one that refuses, so the whole shuffle is one transaction.
Silence is the failure mode to design out: a guard that skips the file it cannot
parse, a rule that passes because it was never asked, a rescue that swallows.

### `no-industry-terms` — No industry terms in code; use the generic word

**Code and documents use words a reader outside the industry would understand.** A
term of art asks every reader to have been in the room where it was learned, and
the reader who has not cannot tell a rule from a ritual.

The distinction that matters: **the rules of a domain are worth modelling; the
vocabulary around them is not.** How positions move when two participants meet is
the domain. That the participants are chess players, that an equal result is called
a draw, that a weaker player winning is called an upset — none of that is. Name a
thing for what the code does with it, and keep the industry's own word in data,
where it can change without a deploy.

When the generic word and the specialist word both fit, the generic one wins. This
binds identifiers, comments, tests and these documents; it does not bind a quotation
of the brief, which is reproduced as written.

There is a real counter-argument — matching the client's spoken vocabulary reduces
translation errors between conversation and code — and it is answered in
[`decisions/plain-words-in-code.md`](decisions/plain-words-in-code.md), which also
records the cost of overriding it.

*Produces* `plain-words-in-code`, which is guarded in the half that can be: a cop
holds a list of banned terms and fails the build on any of them. **What belongs on
that list is the judgement, and no check makes it.** A principle producing a law
that is half-checkable is the usual case, not a compromise — the checkable half is
what stops the debt accumulating while the judgement is being argued.

### `one-way-to-say-each-thing` — One way to say each thing; variation is the defect

Repetition of an identical shape is fine — it is greppable and safe to change
everywhere at once. Two ways of expressing one operation is the defect: every
rule about that operation must then know both, and the third way is invisible
until it fails.

---

## SOLID

The five that name how objects are shaped. They are principles like the rest —
judgements, unchecked, and each one produces law only where it produces something
checkable.

### `single-responsibility` — One reason to change

A class exists because one concern owns it, and it changes when that concern
changes. Two reasons to edit a file means two classes sharing one. Optional
attributes piling up on a record is the same tell in the schema: several concepts
sharing a table, with the nulls marking the seam.

*Produces* `no-nullable-columns`, and the object boundaries the constitution asks
for.

### `open-closed` — Extend by adding, not by editing

A new case should arrive as a new object the existing code already knows how to
call, not as another branch inside a method that has to be re-read and re-tested.
Where a rule genuinely has a fixed, small set of cases — three match results, not
an open family — a plain conditional is honest and an abstraction invented to avoid
it is not. The test is whether the set is expected to grow.

### `liskov-substitution` — A subtype keeps its parent's promises

Anything accepting a type must work with every subtype of it, without asking which
one it has. A subclass that raises where its parent returns, or narrows what it
accepts, is not a subtype — it is a different thing wearing the name. In practice
this rules out the `is_a?` check that exists to work around one implementation.

### `interface-segregation` — Depend on what you call, not on what exists

An object should not be handed a collaborator with twenty methods so it can call
one. It also should not be handed a whole record so it can read one field, or a
whole database so it can read one row. An object that owns a decision takes the
values that decision needs, and nothing else.

### `dependency-inversion` — The rule does not reach for its plumbing

The object holding a decision does not open a connection, read a config file or
find its own collaborators. They arrive as arguments. The caller — which already
knows where it is running — supplies them. That is what makes a rule testable
without a database and reusable from a second caller.

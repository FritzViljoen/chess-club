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
restate the rule locally under a comment promising to keep it in sync. The
ranking rules are the worked example: one object owns them, it knows nothing
about the database, and every caller goes through it.

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

### `plain-words-over-jargon` — Plain words over jargon

Code and documents use words a reader outside this hobby would understand. The
rules of the ranking are the domain; the vocabulary of a chess club is not. So a
contest between two players is a *game*, an equal result is a *tie*, and the
ranked list is the *standings*. When the plain word and the specialist word both
fit, the plain one wins.

### `one-way-to-say-each-thing` — One way to say each thing; variation is the defect

Repetition of an identical shape is fine — it is greppable and safe to change
everywhere at once. Two ways of expressing one operation is the defect: every
rule about that operation must then know both, and the third way is invisible
until it fails.

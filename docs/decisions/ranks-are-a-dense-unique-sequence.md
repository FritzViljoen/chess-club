# ranks-are-a-dense-unique-sequence — Ranks are exactly `1..n`, one member per rank

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Enacts:** constitution → `ranks-are-a-dense-unique-sequence`
- **Reference:** [`domain/ranking.md`](../domain/ranking.md)

## Context

The brief says members are ranked `1..n`, 1 being the strongest. It does not say
what happens to the numbers when a member joins or leaves, or whether two members
may share a rank.

Two shapes were available. **A score** — each member holds a rating, and rank is
derived by ordering — is what a real rating system does, and it makes ties and
gaps a non-question. **A position** — each member holds their rank as an integer —
is what the brief describes, and it makes the ranking rules expressible exactly as
written.

## Decision

**Rank is a stored integer, and the set of ranks is always a permutation of
`1..n`.** No rank is shared, none is skipped, and the largest equals the number of
members. Adding a member appends at `n + 1`. Removing one closes the gap by
shifting everyone below up.

A unique index on `rank` holds the uniqueness. A test asserts the full
permutation invariant after every operation that can move a rank.

## Rationale

The brief's rules are written in positions, not points: "move one rank down",
"move up by half the difference between their original ranks". Implemented over a
derived ordering, each of those becomes a search for what rating would produce the
required position — arithmetic the brief never asks for, with rounding decisions
of its own. Stored positions let the rules read as they are written, which is what
makes them checkable against the brief's worked examples.

Density is what makes "half the difference" mean anything. If ranks could have
gaps, the difference between rank 10 and rank 16 would not be six places, and the
example in the brief would not produce the answer the brief gives.

The unique index rather than a model validation follows
`the-schema-states-the-invariant`: a validation cannot see a concurrent write, and
the invariant is the whole basis of the ranking.

## Trade-offs accepted

- **Every shuffle writes several rows.** Moving a member from 16 to 13 touches
  four rows, not one. At club scale this is irrelevant; at thousands of members it
  would not be.
- **The unique index has to be satisfied mid-update.** Writing the new ranks in
  one pass collides with the index part-way through, so the update goes in two
  passes inside the transaction. The index is worth the extra pass.
- **No ties are representable.** Two members cannot share a rank, which is a real
  limitation of the brief's model, not of this decision.
- **A rating system is closed off.** If the club later wants Elo, rank becomes
  derived and this decision is superseded rather than extended.

## Consequences

- `Member#rank` is authoritative and always present.
- Deleting a member is not a simple `destroy`; it resequences. That belongs to the
  same transaction as the delete.
- The standings are `Member.order(:rank)` with no further logic.

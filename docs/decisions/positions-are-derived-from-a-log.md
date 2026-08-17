# positions-are-derived-from-a-log — A position is derived from the contest log, never stored and moved

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Principle:** `one-decision-one-place`, `nothing-fails-quietly`

## Context

The obvious shape puts a `position` on each person and moves it when a contest is
recorded. It is one column, no derived table, and the write is a handful of
`UPDATE`s.

It breaks on a fact about how the data actually arrives: **contests are not
entered in the order they were played.** Somebody types up Saturday's afternoon
on Monday, in whatever order the sheet was filled in, and corrections arrive
later still.

The ranking rules are order-dependent — the same three contests folded in a
different order give different standings, because each one moves the positions
the next one reads. So applying the rules as data arrives makes the answer depend
on typing order rather than on what happened. Two people entering the same
afternoon would get different ladders.

Correction has the same shape. A contest entered with the wrong winner has
already moved positions, and every contest after it read those positions. Undoing
it means inverting the rules, which is not always possible: a capped climb and an
uncapped one land in the same place, so the state does not say what was applied.

## Decision

**Contests are the log and the only thing written by hand. Positions are derived
from them.**

`standings_cache` holds the current order. After every change to the log —
somebody joining, a contest recorded, corrected or removed — the table is
discarded and recomputed from scratch, inside the same transaction as the write.

The recompute is **total, every time.** There is no incremental path and no
high-water mark.

`CalculateStandings` performs it: two arrays in, an array of `Standing` out, no
database. `WriteStandingsCache` persists that answer and holds no rule.

## Rationale

**Entry order stops reaching the answer.** The fold reads `played_at`, so the
same contests in any entry order give one ladder. That is the whole point, and it
is a test.

**A correction is just another recompute.** Editing a contest and rebuilding
gives the ladder that would have existed had the right thing been typed first
time. No inversion, no compensating move.

**One code path cannot disagree with itself.** An incremental update applied on
top of the cache would be a second implementation of the same arithmetic reached
from a different starting point, and a drift between the two is invisible — the
cache is simply wrong and nothing reports it. The shortcut was designed and then
dropped for exactly this reason.

**The cost is small and known.** A recompute is O(contests) over a log of a few
hundred rows folded in memory. At a size where that stops being true, the answer
is a snapshot to fold forward from, not a second write path.

### Alternatives rejected

- **A `position` column moved as contests arrive.** Simplest, and wrong here for
  the reason above: it makes the standings a function of typing order.
- **A cache extended in place when the new contest is later than every other.**
  Correct in the common case and a genuine saving, but it is a second starting
  point for the same fold, and its disagreement with a full rebuild would be
  silent. Rejected for a total recompute (principle → `one-way-to-say-each-thing`).
- **A rating that positions are sorted from.** The brief's rules are positional —
  "move one rank down", "half the difference between their original ranks" — so a
  rating would have to be reverse-engineered to reproduce them.

## Trade-offs accepted

- **Every write pays for the whole log.** Deliberate, and bounded by the size of
  a group that meets in one room.
- **`standings_cache` can disagree with the log if anything writes outside a
  service.** Nothing does, and `WriteStandingsCache` is the only writer of that
  table — but no constraint enforces it, and a console session could.
- **No foreign key on the cache.** The rows are derived and replaced wholesale,
  so a constraint would only fire between a delete and the recompute that is
  about to make the row correct — an obstacle rather than an invariant.

## Consequences

- Nothing anywhere assigns a position.
- A contest can be entered, corrected or removed at any time, and the standings
  follow.
- `joined_on` decides where somebody starts, so back-dating a joiner reorders the
  seed rather than appending them to today's ladder.

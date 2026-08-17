# the-brief-is-silent-at-two-edges — Where the brief says nothing, the code still has one answer

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Principle:** `nothing-fails-quietly`, `one-way-to-say-each-thing`

## Context

The brief gives three rules and one worked example:

> If the lower-ranked player beats a higher-ranked player, the higher-ranked
> player will move one rank down, and the lower level player will move up by half
> the difference between their original ranks.
>
> For example, if players ranked 10th and 16th play and the lower-ranked player
> wins, the first player will move to rank 11th and the other player will move to
> rank (16 - 10) / 2 = 3 placed up, to rank 13th

That example has an even gap of six and lands cleanly. Two situations it does not
cover come up in ordinary play, and the code needs an answer for both — an
unstated rule is not a rule, it is whichever branch happened to be written.

**An odd gap.** Positions 10 and 15, the lower player wins. Half of five is two
and a half. There is no rank 12.5.

**A gap of exactly two.** Positions 10 and 12, with somebody at 11, and the
player at 12 wins. The demotion sends 10 down to 11. The climb, `2 / 2`, sends 12
up to 11 as well. Both moves want one slot, and only one can have it. No other
gap collides: at three or more the winner's target is always below the loser's
new position, and at one the two simply exchange places.

## Decision

**Both are ruled on here, and both are open questions for the group.** The code
has one answer so that it is testable and consistent; the ruling is provisional
and the spec lists it as such.

**An odd gap rounds down.** `gap / 2` is integer division. Positions 10 and 15
give a climb of two, landing on 13.

**At a gap of two, the demotion wins and the climb is capped to nothing.** The
loser ends at 11, the person who was at 11 rises to 10, and the winner stays at
12.

## Rationale

**Rounding down is the conservative reading.** "Half the difference" is already
an approximation of a distance; taking the smaller whole number never moves
somebody further than the brief allows, whereas rounding up moves them further
than half.

**The demotion is the unconditional half of the rule.** The brief states "the
higher-ranked player will move one rank down" flatly, with no arithmetic and no
qualification. The climb is a computed quantity, already rounded, already
approximate. When the two contradict each other, the softer of the two gives —
and the climb is plainly the softer.

**The alternatives each break something stated.** Letting the climb win sends the
demoted player down two ranks, contradicting "one rank down". Exchanging the two
outright moves both by two and honours neither clause.

**One answer beats a correct-looking absence of one.** Left unruled, the outcome
would be whatever the implementation happened to do at that branch, and nobody
reviewing it could tell a decision from an accident
(principle → `nothing-fails-quietly`).

## Trade-offs accepted

- **These are guesses, and they are labelled as guesses.** The spec's *Open
  questions* section carries both, so a reviewer sees a provisional ruling rather
  than a settled rule.
- **A capped climb is not reversible from the stored positions.** A climb of zero
  and a climb capped to zero land in the same place. This costs nothing here only
  because the standings are recomputed from the log rather than unwound
  (see [`positions-are-derived-from-a-log`](positions-are-derived-from-a-log.md)).
- **Changing either ruling changes historic standings.** Since the ladder is
  recomputed from the whole log, a different rule reorders everything, not just
  contests recorded after the change.

## Consequences

- `CalculateStandings` names both cases and has a test for each, including the
  brief's worked example asserted by name.
- The two rulings are listed in the spec under *Open questions*, to be put to the
  group rather than guessed at a second time.
- A third silence found later gets added here rather than settled in a branch.

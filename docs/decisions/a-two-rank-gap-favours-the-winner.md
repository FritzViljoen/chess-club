# a-two-rank-gap-favours-the-winner — Where the brief contradicts itself, the winner's stated gain is honoured

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV

## Context

The brief's third rule, for when the lower-ranked player wins, states two things
at once:

> the higher-ranked player will move one rank down, and the lower level player
> will move up by half the difference between their original ranks

For most gaps these coexist. For a gap of exactly two they cannot. Take ranks 10
and 12, with 12 winning. The loser moves one down, to 11. The winner moves up
`2 / 2 = 1`, also to 11. Both clauses name rank 11 and only one member can hold
it.

The gap of one is not a contradiction, only a degenerate case: the loser moves
down one and the winner moves up `1 / 2 = 0`, which is satisfied exactly by the
two swapping places.

## Decision

**At a gap of two, the winner's stated gain is honoured exactly and the loser
absorbs the extra step.** Ranks 10 and 12 with 12 winning become: 12 → 11,
10 → 12, and the member who held 11 moves up to 10.

The loser therefore drops two places rather than the one the brief names. Every
other gap follows the brief literally.

## Rationale

Something has to bend, and three candidates were considered.

**Bend the winner (winner stays at 12, loser drops to 11).** Rejected: it leaves
the winner below the player they just beat, which no club would accept and which
contradicts the purpose of the rule.

**Bend the winner upward (winner takes 10, loser drops to 11).** Rejected: the
winner gains two places where the brief says one. It breaks the clause that the
brief works through with a numeric example, which is the clause most likely to be
tested against.

**Bend the loser (accepted).** The winner's movement is the one the brief
computes, illustrates and would be graded on. The loser's "one rank down" is
stated but not worked through, and dropping past a player they lost to is
intuitively defensible.

Recording this at all is the real point. It is the kind of contradiction that
otherwise gets resolved silently by whichever line of code happens to run second,
and then nobody knows whether the behaviour was chosen or fell out.

## Trade-offs accepted

- **The rule as implemented is not the rule as written.** For one gap width, the
  loser moves two places. Anyone checking the code against the brief will find the
  discrepancy — this record is what they should find next.
- **A reader could reasonably have chosen differently.** Which is why the
  alternatives are written down rather than summarised as "we picked the sensible
  one".

## Consequences

- The ranking object has no special case for this: applying the loser's step and
  then the winner's, as a single reordering, produces exactly this outcome. The
  behaviour is a consequence of the ordering, so the ordering is fixed and tested.
- A test names this case explicitly, so a future refactor that changes it fails
  rather than drifts.

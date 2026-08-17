# Ranking

How a recorded game changes the standings.

## The standings

Every member holds a rank. The ranks are exactly `1..n` with one member each — no
ties, no gaps — and 1 is the strongest player
(constitution → `ranks-are-a-dense-unique-sequence`). A new member appends at
`n + 1`; removing a member closes the gap.

## Vocabulary

The brief uses the vocabulary of the game. The code does not
([`plain-words-in-code`](../decisions/plain-words-in-code.md)). The mapping, once:

| The brief says | The code says |
|---|---|
| match | `Game` |
| draw | `tie` |
| leader board | `standings` |
| an upset | the lower-ranked member wins |

## The rules

Take the two members of a game. Call the better-ranked one **`high`** (the lower
number) and the other **`low`**, and let `gap = low.rank - high.rank`.

**`high` wins.** Nothing changes.

**A tie.** If `gap` is 1, nothing changes. Otherwise `low` swaps with the member
one rank above them.

**`low` wins.** `high` swaps with the member one rank below them. Then `low` is
lifted `gap / 2` positions — integer division — above their original rank, and
everyone between shifts down one place.

That is the whole rule set. There is no separate case for adjacent members: when
`gap` is 1 the member one rank below `high` *is* `low`, so the swap moves `low` up
one, and `gap / 2` is zero, which leaves them there. An adjacent win by the weaker
player is a straight exchange, and it falls out rather than being handled.

## The brief's worked examples

| Before | Result | After |
|---|---|---|
| 10 and 15 | tie | 15 → 14, 10 unchanged |
| 10 and 11 | tie | no change |
| 10 and 16 | 16 wins | 10 → 11, 16 → 13 |

Take the last one step by step. `high` is 10, `low` is 16, `gap` is 6. Rank 10
swaps with rank 11, so `high` lands on 11. Then 16 is lifted `6 / 2 = 3` places
above its original rank, to 13, and the members who held 13, 14 and 15 each shift
down one. Both numbers match the brief.

## Where the brief contradicts itself

At a `gap` of exactly 2 the two halves of the third rule name the same rank and
cannot both hold. The resolution — the winner's stated gain is honoured, the loser
absorbs the extra step — is
[`a-two-rank-gap-favours-the-winner`](../decisions/a-two-rank-gap-favours-the-winner.md).
Read it before changing anything here.

## Where this lives in the code

One plain object owns these rules
(constitution → `the-ranking-rules-live-in-one-object`). It takes the current
standings and a result, and returns the ranks that changed. It runs no queries and
holds no records, so the worked examples above are its tests, written directly.

Applying those changes — persisting the game, writing the new ranks, incrementing
both members' game counts — happens in one transaction
(constitution → `a-game-is-recorded-in-one-transaction`). A half-applied shuffle
would leave the standings in a state none of these rules allows.

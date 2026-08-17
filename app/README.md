# Application

Server-rendered ERB with the Rails 8 defaults — Propshaft, importmap, Turbo. No
separate front end and no build step.

## Screens

| Route | Shows |
|---|---|
| `/` | The standings: every member in rank order |
| `/members` | Member list, with new, edit and delete |
| `/games/new` | Record a game: two members and one of three results |

The standings are the root because they are what the club looks at.

## Where the rules live

**Not in a controller and not in a model callback.** One plain object owns the
ranking rules (constitution → `the-ranking-rules-live-in-one-object`): it takes the
current standings and a result and returns the ranks that changed. It runs no
queries. A second object applies the result — persisting the game, writing the new
ranks, incrementing both members' game counts — in one transaction
(constitution → `a-game-is-recorded-in-one-transaction`).

A controller collects input and calls that. If a rank is being computed anywhere
else, that is the defect.

The rules themselves are in [`../docs/domain/ranking.md`](../docs/domain/ranking.md).

## Naming

`Member`, `Game`, `standings`, `tie`. Plain words, not the vocabulary of the game
([`plain-words-in-code`](../docs/decisions/plain-words-in-code.md)) — so no `Match`,
no `draw`, no leaderboard, and the case where the weaker member wins is named for
what it is.

## Models hold defaults, the schema does not

No column carries a database default
(constitution → `no-database-defaults`), so a starting value — a new member's game
count, their rank at `n + 1` — is decided in the model, where a reader and a test
can both see it.

Every attribute is present. No column in this schema is nullable
(constitution → `no-nullable-columns`), so there are no nil branches to write and
none should appear.

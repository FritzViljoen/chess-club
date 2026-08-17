# Domain

What the app does, stated as it should be — not as it currently happens to be
built.

| Document | Covers |
|---|---|
| [`ranking.md`](ranking.md) | The standings, and how a recorded game changes them |

## The shape of it

A **member** belongs to the club and holds a rank. A **game** is a contest between
two members with one of three results: either member wins, or it is a tie.
Recording a game updates the standings and both members' game counts.

That is the whole domain. The interesting part is the ranking, which is why it has
a document of its own.

## What a member is

Name, surname, email address, birthday, the number of club games they have played,
and their current rank. Every one of those is required — there is no such thing as
a member without a rank, and no column here is nullable
(constitution → `no-nullable-columns`).

## What a game is

The two members, the result, the date it was played, and a record of both ranks
before and after. The before-and-after pair is not redundant: it is what lets the
club answer "why is this member ranked here" after the fact, and what makes a
shuffle auditable rather than merely correct.

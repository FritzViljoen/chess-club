# Ranked standings — design

*The shape of the application: what it stores, what it derives, and the rules
that move a position.*

---

## Purpose

A small group ranks its people from 1 to n, where 1 is the strongest. People are
added, edited and removed. Contests between them are recorded. Recording a
contest moves positions according to a fixed set of rules, and a standings view
shows the current order.

---

## Vocabulary

The brief speaks the vocabulary of the pastime. The code does not, per
[`plain-words-in-code`](../decisions/plain-words-in-code.md). The mapping is
stated here, once, and nowhere else.

| The brief says | The code says | Why |
| --- | --- | --- |
| member | `Person` | `member` is a banned term |
| match, game | `Contest` | `game` is a banned term; a contest is an occasion on which participants are placed against each other |
| a player's part in a match | `ContestResult` | names what the row holds — a person and where they finished |
| draw | a `tie` — two results sharing a `place` | plain word for an equal outcome |
| upset | no name | a term of art; the branch is named for what it tests |
| rank | `position` | plain word, and it is what the column holds |
| leaderboard | `standings` | plain word for the ordered list |
| number of games played | a count over results | derived, not stored |

Quotations of the brief in this document are reproduced as written, which the
law permits.

---

## Source of truth

**Contests are the log. Positions are derived from it.**

The obvious design keeps a `position` on each person and moves it when a contest
is recorded. It does not work here, because **contests are not entered in the
order they were played.** The rules are order-dependent — the same three
contests folded in a different order give different standings — so applying them
as data arrives makes the standings depend on typing order rather than on what
happened.

So nothing writes a position directly. `standings_cache` holds the current order
and is discarded and recomputed from the log after every change to it, in the
same transaction as the write. Recomputing is what makes a correction possible: a
contest entered with the wrong outcome is edited and every position that followed
from it is recomputed. Reversing the rules in place is not always possible.

**The recompute is total, every time.** No incremental path, no high-water mark.
It is O(contests) over a log of a few hundred rows folded in memory, and one code
path cannot disagree with itself.

---

## Schema

Every column is `NOT NULL` with no database default, per
[`no-nullable-columns`](../decisions/no-nullable-columns.md) and
[`no-database-defaults`](../decisions/no-database-defaults.md).

### `people`

| Column | Type | Notes |
| --- | --- | --- |
| `name` | string | |
| `surname` | string | |
| `email` | string | unique index; required, and how a person is identified |
| `born_on` | date | the brief's "birthday" |
| `joined_on` | date | entered on the form |

`joined_on` orders the ladder before any contest is folded, so it is asked for
rather than read off `created_at` — otherwise the starting order would depend on
when a row happened to be typed in.

**Email identifies a person from outside this database.** The brief gives no
number to use instead, and `id` is an implementation detail nobody outside would
think to quote — so email is required and unique, and the unique index is what
makes that true rather than the validation. URLs still route on `id`: an address
gets corrected, and a link that breaks when it does is worse than an opaque one.
See [`email-identifies-a-person`](../decisions/email-identifies-a-person.md),
which supersedes an earlier ruling that email was optional.

### `contests`

| Column | Type | Notes |
| --- | --- | --- |
| `played_at` | datetime | entered on the form, date and time |

A moment rather than a date, because several contests happen on one afternoon and
the rules are order-dependent. With a date alone their order would fall back to
`id`, which is entry order — and entry order is exactly what this design exists
to stop mattering.

This is the one place the application handles a time rather than a date, so it is
held to `a-time-names-its-zone`: the form's value is read at the seam with an
explicitly named zone and reaches a service as an `ActiveSupport::TimeWithZone`.
The zone the group plays in is named once, as an IANA string, and passed in —
never read from an ambient `Time.zone`.

### `contest_results`

| Column | Type | Notes |
| --- | --- | --- |
| `contest_id` | reference | |
| `person_id` | reference | |
| `place` | integer | 1 is best; equal values are a tie |

Unique index on `(contest_id, person_id)`. A person appears once in a contest.

### `standings_cache`

| Column | Type | Notes |
| --- | --- | --- |
| `person_id` | reference | unique index |
| `position` | integer | unique index; 1..n contiguous |

Derived. Truncated and rewritten by a recompute; never edited in place, and never
written by anything else. The model is `StandingsCache`, which names its table
explicitly.

---

## Two participants now, more later

`contests` has many `contest_results` because a contest between two people and a
contest between six differ only in how many rows hang off it. The brief covers
two, so **a validation requires exactly two results**, and the rules below are
stated for two.

Supporting more than two changes that validation and the rules that read the
results — no migration. What those rules should be is not inferred here: the
brief does not say how a six-way contest moves positions, and guessing is worse
than the validation.

---

## The rules

The calculation holds an ordered list of person ids. Position is the 1-based
index into it. Seeding appends people in join order, which is the brief's "New
players will, by default, be ranked last". A contest applies the rules below.

Let `better` be the participant in the lower-numbered position before the
contest and `worse` the other. Who won is a separate question from who stood
higher: the winner is the participant with the lower `place`, and the rules exist
for what happens when those are not the same person.

Let `a` be `better`'s position, `b` be `worse`'s — both read before anything
moves — and `gap = b - a`.

**The person in the better position wins.** Nothing moves.

> If the higher-ranked player wins against their opponent, neither of their ranks change

**A tie.** If `gap == 1`, nothing moves. Otherwise `worse` moves up one position,
displacing the person above them.

> If it's a draw, the lower-ranked player can gain one position, unless the two players are adjacent.

**The person in the worse position wins.** `better` moves down one position. Then
`worse` moves up `gap / 2` positions, integer division, measured from the
positions before either move — with the exception below.

> the higher-ranked player will move one rank down, and the lower level player will move up by half the difference between their original ranks

A move is a removal from the list and an insertion at the target index. Everyone
between shifts to fill in.

### Worked example, from the brief

Positions 10 through 16 hold A, B, C, D, E, F, G. G wins against A.

1. A moves down one, to 11. B rises to 10.
2. `gap` is 6, so G moves up 3, from 16 to 13. D, E and F each shift down one.

Final: B 10, A 11, C 12, G 13, D 14, E 15, F 16 — which is the brief's answer,
A at 11 and G at 13.

### The two edges the brief does not cover

Both are ruled on here so the code has one answer, and both are listed under
*Open questions*, because a provisional ruling is not a confirmed one.

**An odd gap.** `gap / 2` rounds down. Positions 10 and 15, the worse-positioned
person wins: the climb is 2, not 3, landing on 13. The brief's only worked
example has an even gap.

**A gap of exactly 2.** Positions 10 and 12, somebody at 11, and the person at 12
wins. The demotion sends 10 down to 11; the climb, `2 / 2`, sends 12 up to 11 as
well. Both moves want one slot.

**The demotion wins and the climb is capped to nothing.** A ends at 11, the person
at 11 rises to 10, the winner stays at 12. The brief states the one-position drop
unconditionally, while the climb is already a rounded-down approximation of half
a gap — so the climb is the softer rule, and it gives.

No other gap collides: for `gap >= 3` the winner's target is always below the
loser's new position, and `gap == 1` is a straight exchange.

---

## The recompute

Load everything, calculate, write the answer:

1. **Load** every person and every contest result.
2. **Seed** the list with those people, ordered by `joined_on`, then `id`.
3. **Fold** the results onto it, grouped into contests and ordered by
   `played_at`, then `contest_id`.
4. **Write** the resulting order to `standings_cache` as `1..n`.

Steps 2 and 3 are one calculation over two arrays, with no database in it. The
sort orders are part of the calculation, not of the query — how the ladder starts
is a rule of the domain, and a rule stated inside an `ORDER BY` is a rule that
cannot be tested without a table.

Every join happens before every contest. That is sound because a person is always
created before any contest naming them — the one ordering the application can
enforce — and because a person who has played nothing does not move, so seeding
them early changes no one else's position.

`id` and `contest_id` break ties. Not as a claim about time: the fold must be
deterministic, and two rows sharing a moment have no other order.

### Validations

- A contest has exactly two results, belonging to two different people.
- At least one result in a contest has `place` 1.
- A contest's `played_at` does not precede a participant's `joined_on`. The fold
  does not need this — seeding puts everyone in place first — but a contest
  predating a participant is bad data, and it is one line to refuse.

### Removal

Removing a person removes their results and every contest they took part in — a
contest with one participant is not a contest — and then recomputes. History
naming a removed person does not survive them.

---

## Objects

Two objects, split by what they do rather than by what they are about.

**`CalculateStandings`** takes two arrays — every person and every contest result
— and answers with an ordered list of person ids. It orders the people by join
date into the starting standings, groups the results into contests, folds each
contest through the rules, and returns what is left. **No database, no writing**
— arrays in, array out. Every rule above is tested here by handing in two
literals and comparing to a third.

**`WriteStandingsCache`** takes that ordered list and persists it to
`standings_cache` as `1..n`. It is the only writer of that table, and it holds no
rules — it does not know why the order is what it is.

The split is the point: the object that decides anything is the one that touches
nothing, so it can be exercised without arranging a database first
(principle → `dependency-inversion`).

Everything that writes is a service in `app/services/`, one operation per class:
`CreatePerson`, `UpdatePerson`, `RemovePerson`, `CreateContest`, `UpdateContest`,
`RemoveContest`. Each persists its own change, loads the two collections, hands
them to `CalculateStandings` and passes the answer to `WriteStandingsCache` — all
inside one transaction, because a half-applied shuffle is worse than a refused
one.

`RecalculateStandings` is the one caller that runs both steps, so a write service
says what it wants rather than repeating the sequence. `ReadStandings` answers
with the ordered rows for the view, reading `standings_cache` and nothing else.

`LocalZone` names the zone, as an IANA string, in one place. Both the contest
validation and the seam read it; nothing reads an ambient `Time.zone`.

No model registers a callback, per
[`no-lifecycle-callbacks`](../decisions/no-lifecycle-callbacks.md). The recompute
is called by the code that decided to write, which is the code that knows one is
due.

---

## Screens

- **People** — index, show, new, edit, remove. The form asks for name, surname,
  email, `born_on` and `joined_on`.
- **Contests** — index, showing when it was played, the participants and the
  outcome, in the order the fold takes them. New, edit, remove. The form asks for
  a date and a time.
- **Standings** — position, name, contests played. The view the group looks at.

Contests played is a count over `contest_results`, not a stored column. A stored
count is a second answer that can disagree with the log.

---

## Testing

- The rules get table-driven unit tests with no database: the better-positioned
  person wins, a tie at every gap including 1, and the worse-positioned person
  winning at gaps 1 through 6. The brief's worked example is a test by name.
- A recompute test proves the fold is deterministic — the same log twice, the
  same order — and that a person with no contests lands where `joined_on` seeds
  them.
- An out-of-order test enters the same three contests in three different entry
  orders and asserts the standings are identical. This is the test the whole
  design exists for.
- A correction test edits a contest in the middle of a log and asserts the later
  positions moved with it.
- Integration tests cover the three flows end to end: add a person, record a
  contest, read the standings. They also cover the seam — a date or time the
  parsers cannot read bounces the request and stores nothing.

---

## Open questions

To put to the group, not to guess at a second time.

1. **Odd gaps round down.** Positions 10 and 15, the worse-positioned person
   wins: is the climb 2 or 3? Ruled: 2.
2. **A gap of exactly 2 over-determines one slot.** Ruled: the demotion applies
   and the climb is capped to nothing. The alternative — the climb applies and
   the demoted person falls two — contradicts the brief's unconditional wording.
3. **More than two participants** has no rules in the brief at all. The schema is
   ready; the rules are not written.

---

## Decision records this produces

Each is a choice with a defensible alternative, so each gets a record per
[`a-non-trivial-choice-is-a-decision-record`](../constitution.md).

- `positions-are-derived-from-a-log` — why a cache recomputed in full, rather
  than a `position` on each person moved as contests arrive. The reason is
  out-of-order entry, and the record says so.
- `a-contest-holds-results` — why the join table exists while a validation allows
  only two.
- `the-brief-is-silent-at-two-edges` — the rounding and the collision, with the
  alternatives rejected.

---

## Built on

`Service`, `Result`, `TypedArguments`, `Boolean` and `TypedParams`. The services
above are written against them, and `played_at` is the value that makes the zone
half of `a-time-names-its-zone` load bearing here — the one moment this
application stores.

---

## Out of scope

Authentication, reversing a contest without a recompute, incremental recomputes,
pagination, and any rule for contests with more than two participants.

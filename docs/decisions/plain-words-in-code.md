# plain-words-in-code — Identifiers use plain words, not the vocabulary of the hobby

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Enacts:** constitution → `plain-words-in-code`
- **Principle:** `no-industry-terms`

## Context

The obvious naming for this app borrows the vocabulary of the game: a `Match`
between two players, a `draw`, an *upset* when the weaker player wins, a
*leaderboard*. Domain-driven design would call that the ubiquitous language and
recommend it.

It also means every reader has to know the hobby to read the code. `upset` in
particular is a term of art: it names a specific outcome, it is not obvious from
the word itself, and half the branches in the ranking rules would be named after
it.

## Decision

**Identifiers use plain words.** A contest between two members is a `Game`. An
equal result is a `tie`. The ranked list is the `standings`. The case where the
lower-ranked member wins is named for what it is, not called an upset.

This binds code, tests and these documents. It does not bind the brief, which is
quoted as written.

## Rationale

The rules of the ranking are the domain worth modelling; the jargon around them is
not. Nothing in `Game`, `tie` or `standings` loses information relative to the
specialist term, and each is understood by a reader who has never been in a club.
Where a plain word and a specialist word both fit exactly, the plain one costs
nothing and asks less.

The rule also survives the app being about something else. The ranking mechanic —
positions that move when two participants meet — is not specific to one game, and a
codebase named after positions and results rather than one hobby's vocabulary is
the one that could be reused.

There is a real counter-argument: matching the client's spoken vocabulary reduces
translation errors between conversation and code. It is accepted below.

## Trade-offs accepted

- **A translation step in conversation.** The club says "match" and "draw"; the
  code says `Game` and `tie`. Anyone moving between the two has to map them, which
  is exactly the cost DDD's ubiquitous language exists to avoid.
- **The brief and the code disagree on words.** The mapping is stated once, where
  the domain is described, so the disagreement is documented rather than confusing.
- **No check enforces it.** Whether a word is jargon is a judgement, so this is
  held by review and by this record — see the constitution, which says so beside
  the law.

## Consequences

- Model names: `Member`, `Game`. Outcome values name the participants and the tie,
  not the game's terms of art.
- The standings view is `standings`, not a leaderboard.
- A reviewer rejecting a jargon name cites this record rather than arguing taste.

# Decisions

*Layer 3. Enacted under the [constitution](../constitution.md).*

One claim per file, each carrying its full reasoning. A decision may add or
refine law; **none may contradict the constitution**. On conflict the
constitution governs and the decision is corrected, or the constitution is
amended by a decision that names the law it changes.

## Conventions

- **Named, not numbered.** A file is `the-claim-in-kebab-case.md`, and that name
  is the citation. See
  [`decisions-are-named-not-numbered.md`](decisions-are-named-not-numbered.md).
- **One decision per file.** If a record needs the word "also", it is two
  records.
- **Superseding, not deleting.** A reversed decision is marked superseded and
  left in place; the superseding record links back to it. The reasoning behind a
  closed road is what stops it being walked again.
- **Shape:** Status, Context, Decision, Rationale, Trade-offs, Consequences. A
  page is usually enough. Length is not evidence of thought.

## The record

| Decision | Claim |
|---|---|
| [`decisions-are-named-not-numbered`](decisions-are-named-not-numbered.md) | A decision is cited by its claim, never by a number |
| [`plain-words-in-code`](plain-words-in-code.md) | Identifiers use plain words, not the vocabulary of the hobby |
| [`no-nullable-columns`](no-nullable-columns.md) | Every column is NOT NULL |
| [`no-database-defaults`](no-database-defaults.md) | No column carries a database default |
| [`a-nullable-column-lives-inside-one-migration`](a-nullable-column-lives-inside-one-migration.md) | A column may be nullable only between two statements of one method |
| [`no-lifecycle-callbacks`](no-lifecycle-callbacks.md) | No model registers an Active Record lifecycle callback |
| [`arguments-are-typed-at-construction`](arguments-are-typed-at-construction.md) | Every argument of a domain object is type-checked where it arrives |
| [`a-service-returns-a-result`](a-service-returns-a-result.md) | Every service answers with a result — **superseded** |
| [`a-service-answers-with-what-it-made`](a-service-answers-with-what-it-made.md) | Every service answers with the thing itself, not an envelope |
| [`untrusted-input-is-parsed-at-the-seam`](untrusted-input-is-parsed-at-the-seam.md) | Request input is parsed by `TypedParams`, at the seam, and nowhere else |
| [`a-time-names-its-zone`](a-time-names-its-zone.md) | A time value names the zone it is in; nothing reads an ambient one |
| [`positions-are-derived-from-a-log`](positions-are-derived-from-a-log.md) | A position is derived from the contest log, never stored and moved |
| [`a-contest-holds-results`](a-contest-holds-results.md) | A contest holds a collection of results, not two participant columns |
| [`the-brief-is-silent-at-two-edges`](the-brief-is-silent-at-two-edges.md) | Where the brief says nothing, the code still has one answer |
| [`email-identifies-a-person`](email-identifies-a-person.md) | Email is how a person is identified, so it is required and unique |

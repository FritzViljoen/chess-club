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

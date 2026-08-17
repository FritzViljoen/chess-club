# Constitution

*The law. Below the [principles](principles.md), above the
[decisions](decisions/).*

> Each law names the principle it carries out and the guard that holds it. **A
> law with no guard says so** — an unenforced law is a convention, and calling it
> a law does not make it hold. A law that implements no principle is either a
> principle nobody has written down or a rule that should not be law.
>
> A decision may refine a law. None may contradict one: on conflict the
> constitution governs and the decision is corrected, or the constitution is
> amended by a decision that names the law it changes.

---

## `no-nullable-columns` — Every column is NOT NULL

No column in this schema may be nullable. If a value genuinely does not exist
for some rows, that is a missing table, not a missing value.

- **Principle:** `the-schema-states-the-invariant`
- **Guard:** `Schema/NoNullableColumns`, in
  [`lib/rubocop/cop/schema/`](../lib/rubocop/cop/schema/). Fails CI. Covers
  creation and alteration, resolves a reference to the column it really creates,
  and exempts the reverse direction.
- **Decision:** [`no-nullable-columns.md`](decisions/no-nullable-columns.md)

## `no-database-defaults` — No column carries a database default

`created_at` and `updated_at` excepted. A default in the schema is a second,
invisible place deciding a value; the model is the one place that decides.

- **Principle:** `the-schema-states-the-invariant`, `one-decision-one-place`
- **Guard:** `Schema/NoColumnDefaults`. Fails CI.
- **Decision:** [`no-database-defaults.md`](decisions/no-database-defaults.md)

## `a-nullable-column-lives-inside-one-migration` — A column may be nullable only between two statements of one method

A NOT NULL column cannot be added to a populated table in one statement. So a
column may be added nullable, filled, and promoted with `change_column_null` —
and the promotion must come later in the same method. A nullable column that
outlives its migration is what `no-nullable-columns` forbids.

- **Principle:** `the-schema-states-the-invariant`
- **Guard:** the promotion rule inside `Schema/NoNullableColumns`. Fails CI.
- **Decision:**
  [`a-nullable-column-lives-inside-one-migration.md`](decisions/a-nullable-column-lives-inside-one-migration.md)

## `no-lifecycle-callbacks` — No model registers an Active Record lifecycle callback

No `before_save`, `after_create`, `after_commit` or any of their siblings, in a
model or in a concern included into one. Work goes in a named method the caller
invokes.

- **Principle:** `one-decision-one-place`, `nothing-fails-quietly`
- **Guard:** `Model/NoCallbacks`, scoped to `app/models/**/*.rb`. Fails CI.
- **Decision:** [`no-lifecycle-callbacks.md`](decisions/no-lifecycle-callbacks.md)

## `ci-is-one-command` — CI runs exactly what a developer runs

The build runs `bin/ci` and nothing else. Its steps live in `config/ci.rb`, so a
green run locally means a green build, and there is no second list of checks to
drift.

- **Principle:** `one-way-to-say-each-thing`
- **Guard:** none. Nothing reads `.github/workflows/ci.yml`, so a second check added
  there would pass every local command. A guard would be a test that parses the
  workflow and asserts its only `run:` is `bin/ci`; until that exists this law is a
  convention, held by review.

## `plain-words-in-code` — Identifiers use plain words

No industry term in a name. Name a thing for what the code does with it; the
industry's own word belongs in data, where it can change without a deploy.

**This law binds Ruby: identifiers, and the comments and strings beside them.** What
prose in a document may say is the principle's business, not this law's — see
`no-industry-terms`, which asks a document to prefer the generic word and cannot
check that it did.

The banned terms are the authority on what this means in practice, and they are
listed in `.rubocop.yml`, not here — a second copy would be a second answer.

- **Principle:** `no-industry-terms`
- **Guard:** `Vocabulary/BannedTerms`, over `app/**/*.rb`, `db/**/*.rb` and
  `lib/**/*.rb`. Fails CI. It holds a list, in `.rubocop.yml` under `BannedTerms`,
  and reads a name the way a reader does — splitting on separators *and* on case
  humps, so `person_id`, `spare_person`, `PersonCount` and `PERSON_COUNT` all match
  one entry while `personal` does not. Matching is case-insensitive but does not
  inflect, so every plural is listed as its own term. Comments and strings are
  scanned too.
- **Guard's limit:** the list is checkable; **what belongs on it is not.** Adding a
  term is a judgement, and no check makes it.
- **Guard's reach:** those three trees and no others. `config/`, `bin/`, `script/`,
  `Rakefile` and `config.ru` hold Ruby and are **not** covered — the application's
  own namespace, declared in `config/application.rb`, contains a banned term for
  that reason and the guard cannot see it. Widening the globs is the fix if that
  stops being acceptable; pretending it is covered is not.
- **Exempt on purpose:** `test/`, because a fixture naming the term it tests the ban
  on is not a breach of the ban.
- **Decision:** [`plain-words-in-code.md`](decisions/plain-words-in-code.md)

## `a-non-trivial-choice-is-a-decision-record` — A non-trivial choice gets a record, not a code comment

Where two defensible options existed, the reasoning goes in
[`decisions/`](decisions/) so the road not taken stays closed.

- **Principle:** `one-decision-one-place`
- **Guard:** none. Convention, held by review.
- **Decision:**
  [`decisions-are-named-not-numbered.md`](decisions/decisions-are-named-not-numbered.md)

## `a-folder-document-binds-its-whole-subtree` — A folder document states only facts true of its whole subtree

A folder's `README.md` says what the folder is, then states only facts that hold for
every file in it **and in all of its subfolders**. A rule binding part of a tree goes
in that part's own document, not the parent's. Nothing domain-specific: what the
application does is described once, in its own document, not scattered through the
tree.

- **Principle:** `one-decision-one-place`
- **Guard:** none. Whether a fact holds for a whole subtree is a judgement, and no
  check makes it. Held by review.

## `documents-state-the-intended-shape` — A document states how the system should look

Not how it is, and not how it was. A gap between a document and the code is a defect
in the code, unless a decision changes the intended shape — a document is never
edited to record that reality drifted. Present tense, no dates. Historic context
belongs in a decision record, which is the only document that looks backwards.

- **Principle:** `one-decision-one-place`
- **Guard:** none. Held by review.

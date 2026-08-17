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

## `arguments-are-typed-at-construction` — Every argument of a service is type-checked where it arrives

A `Service` takes its arguments in a hand-written `initialize` and passes every
keyword through a `TypedArguments` guard. The guard asserts and never coerces; a
mismatch raises `ArgumentError`, because it is a caller defect and not an answer
anybody is waiting for.

The boundary is the point: inside the service nothing re-checks an argument, and
a failure has a side — at the guard it is the caller's defect, past it the
service's own.

The initializer is written, not generated. A macro that declared the inputs and
built the initializer behind them would hide both the assignment and the
assertion, and `typed(on, Date)` would stop being greppable.

- **Principle:** `nothing-fails-quietly`, `make-the-wrong-thing-impossible`
- **Guard:** `Service/NoUnguardedArguments`, over `app/**/*.rb`. Fails CI. It
  recognises a service by what it inherits, not by where it is filed, and counts
  `typed`, `typed_enum`, `typed_array` and `typed_hash` as guards.
  Anything that is not a named keyword is its own offense — `**options`, `*args`,
  `(...)`, a positional parameter, a positional Hash default. `Service.call(**arguments)`
  hands its keywords to a keyword-less initializer as one positional Hash and the
  call succeeds, so collecting parameters is a hole rather than an impossibility.
- **Guard's limit:** it checks that a keyword is guarded, never that the type
  named is the right one.
- **Decision:**
  [`arguments-are-typed-at-construction.md`](decisions/arguments-are-typed-at-construction.md)

## `a-service-returns-a-result` — Every service answers with a result

`Service#call` returns a `Result` — `success(value)` or `failure(:code)` — and
`Service.call` raises `TypeError` on anything else. A refusal is a code the
caller can handle; a defect raises and is nobody's error message.

A service that reads answers `success(rows)`, the same as one that writes. There
is one shape, so a caller never has to know which kind it is holding, and an
empty answer is an answer rather than a refusal.

Reading and writing are separate services all the same. One operation per class,
and no flag deciding which of the two a call is doing.

- **Principle:** `nothing-fails-quietly`, `one-way-to-say-each-thing`
- **Guard:** `Service.call` itself, which raises rather than passing on whatever
  `call` evaluated to. Tested in both directions.
- **Guard's limit:** nothing checks that a reading service does not write, or
  that a service does only one thing. That is review's.
- **Decision:**
  [`a-service-returns-a-result.md`](decisions/a-service-returns-a-result.md)

## `untrusted-input-is-parsed-at-the-seam` — Request input is parsed by `TypedParams`, at the seam, and nowhere else

A parameter is a string somebody typed. It becomes a Date, an Integer, a decimal,
a boolean or a value from a closed set in `app/controllers/concerns/typed_params.rb`,
and it does so once. Never inline in an action, where `Date.parse(params[:on])`
turns a typo into a 500; never in the domain, which is handed real values and
asserts them.

Each parser has two forms: the plain one answers with the caller's default, the
bang form bounces as `BadParam` — a flash and a redirect for an HTML request, a
plain 400 for anything else.

- **Principle:** `nothing-fails-quietly`, `one-decision-one-place`
- **Guard:** `Controller/NoInlineParamParse`, over `app/controllers/**/*.rb`.
  Fails CI. It flags `parse`, `strptime` and `iso8601` **on any receiver**, the
  raising `Kernel` conversions, and the casts — `to_date`, `to_datetime`,
  `to_time`, `in_time_zone` — whenever the value came from `params`. A zone held
  as `Time.zone`, as `Time.find_zone!(…)`, or as whatever `time_zone_param!`
  answered with is caught alike, called with `.` or `&.`.
- **Guard's limit:** `JSON` and `URI` are exempt, having no parser here to be
  sent to. `to_i` and `to_f` cannot raise and read no zone, so the cop leaves
  them alone; they coerce silently, which is its own defect, and no check catches
  it. Neither does it see a parse of a local assigned from `params` earlier.
- **Decision:**
  [`untrusted-input-is-parsed-at-the-seam.md`](decisions/untrusted-input-is-parsed-at-the-seam.md)

## `a-time-names-its-zone` — A time value names the zone it is in; nothing reads an ambient one

Two halves of one rule.

**At the seam**, `date_param`, `time_param` and their bang forms take
`time_zone:` as a required keyword — a parameter to read the zone from, an IANA
name, or a zone already cast. There is no default: not `Time.zone`, not a
configured setting, and nothing read off the request on the parser's own
initiative. `default: :today` and `default: :now` resolve in that zone, so an
action never reaches for `Date.current`. Where the requester's own zone is
wanted, the action says so — `time_zone: :time_zone` — and a request arriving
without one bounces because that action asked for it, not because every request
must carry it.

**A time that states its own offset must agree with that zone.** Where the string
carries one and the two disagree, the request holds two answers and neither is
taken: it bounces.

**In a service**, a time argument is an `ActiveSupport::TimeWithZone`, asserted
with `typed` like anything else. A `Time` or a `DateTime` carries whatever offset
the process had, chosen by nobody, so it is refused **as a declared type and as a
value**: `typed(at, Time)` raises, and so does a `DateTime` handed in as a
`Date` — which it is a subclass of. A `Date` has no zone and is asserted as
normal.

**A time-like value that is not a moment travels as a String.** A local pick-up
time — "18:30", meaning half past six wherever it happens — is a wall-clock
reading. Building a `Time` for one invents a date and an offset it never had.

- **Principle:** `nothing-fails-quietly`, `one-decision-one-place`
- **Guard:** the required keyword, which is Ruby's own `ArgumentError` at the
  call site; the offset check in `time_param`, which bounces a string that
  disagrees with it; `TypedArguments`'s refusal of `Time` and `DateTime` as types;
  `Service/NoUnguardedArguments`, which fails a keyword no guard asserts; and
  `Controller/NoInlineParamParse`, which forbids the
  `Time.zone.parse(params[...])` that would go around all of it. Each tested.
- **Guard's limit:** nothing yet stops `Time.zone`, `Time.current` or
  `Date.current` being read somewhere else in the application. That wants its own
  cop, and until it exists this half is convention.
- **Decision:**
  [`a-time-names-its-zone.md`](decisions/a-time-names-its-zone.md)

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

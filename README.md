# Chess Club Administration

A small Rails application for ranking people `1..n` by the contests they play
against each other, where 1 is the strongest.

Contests are entered out of the order they were played, and the ranking rules
depend on that order — so no position is ever stored and moved. The contests are
the record, and the standings are recalculated from all of them after every
change. That is what lets a mistyped contest be corrected: everything that
followed from it is worked out again.

The code does not use the vocabulary of the game. A person is a `Person`, a match
is a `Contest`, a draw is a tie, and the ranked list is the standings — see
[`docs/decisions/plain-words-in-code.md`](docs/decisions/plain-words-in-code.md)
for why, and the spec below for the mapping in full.

## Documentation

| If you want | Read |
|---|---|
| How the code is built | [`docs/principles.md`](docs/principles.md) |
| The rules it must obey, and their guards | [`docs/constitution.md`](docs/constitution.md) |
| Why a specific decision was made | [`docs/decisions/`](docs/decisions/) |
| What this application stores and derives | [`docs/specs/2026-08-17-ranked-standings-design.md`](docs/specs/2026-08-17-ranked-standings-design.md) |

Folder-level notes live beside the code: [`app/`](app/README.md),
[`db/`](db/README.md), [`lib/`](lib/README.md), [`test/`](test/README.md),
[`app/views/`](app/views/README.md).

**Where the thinking is.** The commits are grouped by kind of work — schema,
domain, screens, documents — rather than left in the order they happened, so the
history reads as an argument instead of a diary. The reasoning that a
chronological history would have shown lives in
[`docs/decisions/`](docs/decisions/) instead: each record states what was
decided, what the alternatives were, and what the choice costs. Start with
[`email-identifies-a-person`](docs/decisions/email-identifies-a-person.md) and
[`a-service-answers-with-what-it-made`](docs/decisions/a-service-answers-with-what-it-made.md).md).

## Requirements

- Ruby 3.3.5 (see `.ruby-version`)
- SQLite 3

No other services are needed.

## Getting started

```sh
bin/setup
```

That installs gems, prepares the database and starts the server on
http://localhost:3000. To skip the server, run `bin/setup --skip-server`
and start it later with `bin/dev`.

## Tests

```sh
bin/rails test
```

## Everything CI runs

```sh
bin/ci
```

Style, gem and JavaScript audits, Brakeman, the test suite and the seeds.
The GitHub Actions workflow runs the same command, so a green `bin/ci`
locally means a green build. The steps live in `config/ci.rb`.

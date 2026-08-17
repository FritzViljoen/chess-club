# Chess Club Administration

A small Rails application for a local chess club to administer its members
and keep their standings current. Members are ranked `1..n`, where 1 is the
club's strongest player; recording a game updates the standings.

## Documentation

[`docs/`](docs/) holds the written record — how the code is built, the rules it
obeys, and why each was chosen.

| If you want | Read |
|---|---|
| The ranking rules, with worked examples | [`docs/domain/ranking.md`](docs/domain/ranking.md) |
| How the code is built | [`docs/principles.md`](docs/principles.md) |
| The rules it must obey, and their guards | [`docs/constitution.md`](docs/constitution.md) |
| Why a specific decision was made | [`docs/decisions/`](docs/decisions/) |

Folder-level notes live beside the code: [`app/`](app/README.md),
[`db/`](db/README.md), [`lib/rubocop/`](lib/rubocop/README.md),
[`test/`](test/README.md).

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

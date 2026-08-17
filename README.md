# Chess Club Administration

A small Rails application for a local chess club to administer its members
and keep their ranking current. Members are ranked `1..n`, where 1 is the
club's strongest player; recording a match updates the ranking.

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

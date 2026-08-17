# a-time-names-its-zone — A time value names the zone it is in; nothing reads an ambient one

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Enacts:** constitution → `a-time-names-its-zone`

## Context

Every time-like value in Ruby already has a zone, and none of them was chosen by
the code using it. `Time.now` has the process's. `Time.current` and `Date.current`
have `Time.zone`'s — which is thread-local and mutable, so the same expression
means one thing in a request, another in a job, another in a test.

Nothing fails when this goes wrong. The result is a valid time, an hour or two
from the one intended, saved and rendered and never questioned.

An earlier version of this branch required the browser's zone on every request.
That was a footgun — a forgotten hidden field bounced the requester for a
developer's omission, and bookmarks, emailed links and the pre-JavaScript first
load all broke. It also answered the wrong question: the objection is not *whose*
zone, it is that nobody named one.

## Decision

**Every conversion names its zone where it happens, and nothing supplies a
default for it.**

```ruby
date_param!(:on, time_zone: :time_zone)                 # a parameter to read
time_param(:at, time_zone: "Africa/Johannesburg")       # an IANA name
```

`date_param`, `time_param` and their bang forms take `time_zone:` as a required
keyword: a parameter to read the zone from, an IANA name, or the zone
`time_zone_param` casts that name into.
`default: :today` and `default: :now` resolve in that zone, so an action has no
reason to call `Date.current`. Anything that names no zone — missing, blank,
misspelt, an array — is `BadParam(:time_zone)`.

Where the string being read states an offset of its own — "…T10:30:00+05:00", or
a named zone at the end — it has to agree with the zone asked for. A
disagreement bounces, from the plain form as well as the bang one.

In a service, a time argument is an `ActiveSupport::TimeWithZone`.
`typed(at, Time)` raises and says so, and so does a `Time` or `DateTime` passed
as a value under some wider type — `DateTime` is a `Date`, and everything is an
`Object`, so refusing only the declared type would leave the back door open.

A time-like value that is not a moment — a local pick-up time, "18:30" — is a
String. Ruby has no wall-clock type, and a `Time` built to hold one carries a
date and an offset the value never had.

## Rationale

**A required keyword fails at the call site, in development.** A default fails
silently in production, as a slightly wrong hour. That asymmetry is the whole
argument.

**A configured default is still ambient.** Putting the answer in
`config.time_zone` leaves the call site not saying what it meant, and `Time.zone`
still reassignable underneath it.

**A key, a name, or a zone, because casting between them is this module's job.**
The string is what a browser sends and what a config holds; the symbol is the
short way to say "the zone this request sent", which is the common case and
should not need one parser nested inside another; the zone is what
`time_zone_param` already cast, and a caller holding one should not have to hand
back the string it came from. All three are the same cast at different stages.
Everything else — missing, blank, misspelt, an array — is one rejection.

**Two zones in one request is not something to resolve quietly.** `TimeZone#parse`
honours an offset written into the string, so "10:30+05:00" read in
Johannesburg is 07:30 — an answer the caller did not ask for and will not
notice. Refusing it costs a bounce on input that was already contradictory.

**A reading is not a moment, so it does not get a moment's type.** "18:30 at the
venue" has no instant until someone supplies a date and a zone; a `Time` holding
it has silently supplied both, and the first comparison against a real instant
answers on that invention. A String cannot pretend, and whoever has the date and
the zone does the conversion where those are known.

**Both sides of the assertion, because either alone is a hole.** The type is
refused so nobody declares a zoneless time; the value is refused so nobody smuggles
one in as a `Date` or an `Object`. `TimeWithZone` has to be let past first: it
answers `true` to `is_a?(Time)` deliberately, so it can stand in for one, and that
courtesy is precisely what a naive check would trip over.

**`typed(at, Time)` asserts nothing worth asserting.** A `Time` carries an offset
— whatever the process had — so two of them compare cleanly and mean different
o'clocks. `TimeWithZone` carries the zone, and is a type like any other, so it
needs no guard of its own: naming it in `typed` is the whole rule. A `Date` has
no zone, and is asserted the same way.

### Alternatives rejected

- **The browser must send `time_zone` on every request.** What this branch had
  first: the requester bounced for a developer's omission.
- **`config.time_zone` as the parsers' default.** Convenient, still implicit
  where it matters — at the reading.
- **`around_action` setting `Time.zone` per request.** The ambient answer made
  worse: every later reader depends on middleware having run, and the same code
  in a job gets something else silently.
- **An offset in minutes.** A snapshot: the same number means different zones at
  different times of year, and it is wrong after a daylight-saving change.

## Trade-offs accepted

- **Every date and time call site is longer**, by one keyword. That is the value
  saying what it means.
- **This does not say where the application's own zone lives** — a constant, a
  config value, a record. Only that whoever has it names it. That arrives with
  the first screen that needs one.
- **`Time.zone`, `Time.current` and `Date.current` are still callable elsewhere.**
  A cop over `app/` and `lib/` would settle it; until then that half is
  convention.
- **A stated offset that agrees is accepted, not required.** Nothing forces a
  form to send one, so the check only fires when the request volunteered a second
  opinion.
- **A misspelt zone bounces the requester** even when a developer typed it. The
  alternative is a rule about where the string came from, which no signature can
  express.
- **Three accepted shapes for one argument**, where `one-way-to-say-each-thing`
  would prefer one. They are the stages of a single cast — key, name, zone — and
  refusing any of them would make some caller convert a value back into the form
  it started as.

## Consequences

- No time-shaped value in the application carries a zone nobody chose.
- A service is handed a `TimeWithZone` or nothing.
- `time_zone_param` casts the name into a zone, for an action that has to render
  in one or hand it on. A parser needs none of it: the symbol form reads the
  parameter itself.

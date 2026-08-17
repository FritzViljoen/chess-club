# app/controllers

The HTTP seam. An action collects input, calls one object, and renders.

## True of every file here

**No rule is decided here.** A controller does not compute, order, compare or
derive anything a caller elsewhere could need
(principle → `one-decision-one-place`).

**A rule is a service; a lookup is not.** `Person.find`, `Person.new` and the
order a chooser lists people in decide nothing. Choosing between sorts, escaping
a search term or working out which page somebody is on are rules, and live in
`app/services/`. Every write is a service, without exception.

**An id is a parameter.** Active Record coerces a raw string, so
`find(params[:id])` serves person 1 for `1abc` and nothing fails. Guarded by
`Controller/NoUnparsedLookup` (constitution →
`a-parameter-is-parsed-before-it-reaches-a-record`).

**Every parameter is parsed here, by `TypedParams`, and never inline**
(constitution → `untrusted-input-is-parsed-at-the-seam`). Each value reaches its
service by name, which is a narrower allowlist than `permit`.

**A date or a time names its zone**, passed as `time_zone:`. `Time.zone` is
never the answer (constitution → `a-time-names-its-zone`).

**No `before_action` that loads or decides.** An action calls what it needs, by
name, in its own body — otherwise a reader of `show` cannot see where `@person`
came from.

**A failure is rendered, not swallowed.**

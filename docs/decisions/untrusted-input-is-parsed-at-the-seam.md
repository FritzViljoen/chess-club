# untrusted-input-is-parsed-at-the-seam — Request input is parsed by `TypedParams`, at the seam, and nowhere else

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Enacts:** constitution → `untrusted-input-is-parsed-at-the-seam`

## Context

Everything arriving over HTTP is a string somebody else typed, or a string
somebody else forged. Two habits grow out of that, and both are defects.

The first is parsing inline: `Date.parse(params[:on])` in the action. It works
until someone types "yesterdya", and then it is a 500 — a defect page for input
that was merely wrong. `Integer(params[:page])` is the same. `params[:page].to_i`
avoids the 500 by silently answering 0, which is worse: nobody is told anything.

The second is passing the string on. The action hands `params[:on]` to an
operation, which now has to know it might get a string, a Date or nil, and every
operation grows its own answer for bad input.

## Decision

**One module parses request input: `app/controllers/concerns/typed_params.rb`.**
It offers `date_param`, `time_param`, `integer_param`, `decimal_param`,
`boolean_param`, `enum_param`, `time_zone_param` and `text_param`, each with a
bang form.

The plain form answers with the caller's default when the value is missing or
unparseable. `text_param` is the exception: too long refuses in both forms,
because its default is "no search" and a silent fallback would answer an
over-long term with every row there is. The bang form raises `BadParam`, which the concern turns into a
flash and a redirect for an HTML request and a plain 400 for anything else.

`Controller/NoInlineParamParse` fails CI on a raising parse of anything reached
through `params`, whatever the receiver and whether it is called with `.` or
`&.` — `JSON` and `URI` excepted, since neither has a parser here to be sent to.

## Rationale

**Bad input is the requester's problem, and it has to look like one.** Not a
500, and not a page that implies the work was done
(principle → `nothing-fails-quietly`).

**One rule per type, in one place.** What counts as an integer is decided once:
strict base 10, so `"12abc"` is garbage rather than 12. What counts as a boolean
is decided once: what a checkbox and a JSON body actually post, and nothing else
— `"yes"` is not true. A second parser somewhere would be a second answer
(principle → `one-decision-one-place`).

**Two forms, one parse.** The bang form is the plain form plus a raise. The
alternative — a `strict:` flag, or a separate parser — would give the same type
two spellings, and every later rule about parsing would have to know both
(principle → `one-way-to-say-each-thing`).

**`BadParam`, not `ArgumentError`.** Rescuing `ArgumentError` at the controller
would catch every real defect raised anywhere below and render it as a 400. The
narrow class rescues exactly what the parsers raise.

**The rescue wraps the parse and nothing else.** `parsed_param` rescues around
the block's parse call only, so it can never swallow an `ArgumentError` from
further in.

### Alternatives rejected

- **Parse in the action, rescue there.** The rescue gets copied into every action,
  and the third one omits it.
- **Parse in the domain.** Then every operation accepts strings, and
  `arguments-are-typed-at-construction` has nothing left to assert.
- **A form object per action.** More ceremony than a filter needs, and it moves
  the same parsing decisions into a class per screen.
- **`to_i` / `to_f` everywhere.** Never raises, never says anything, and answers 0
  for garbage. The quiet failure this house designs out.

## Trade-offs accepted

- **A default that means "and also missing".** The plain form cannot distinguish
  "absent" from "unparseable" — both give the default. Where the difference
  matters, use the bang form and handle the bounce.
- **The generic bounce is generic.** A flash and a redirect back, with the
  parameter humanised into the sentence. An action wanting better wording uses
  the plain form and bounces itself.
- **The cop cannot see everything.** `to_i` and `to_f` are legal — they cannot
  raise and read no zone — and a parse of a variable assigned from `params` two
  lines earlier is not matched. Matching any
  receiver's `parse` costs the odd false positive on a `parse` that has nothing to
  do with time; naming only `Time.zone` cost every other way of holding a zone,
  which is worse.
- **`Date.parse`, not `Date.iso8601`.** Looser than a strict format, because a
  date field posts what a person can read. A named month has no dd/mm ambiguity;
  an all-numeric one would, and that is a reason to keep posting named months.

## Consequences

- An operation is handed real values, never a parameter string.
- Adding a type means adding a parser here, not a parse at a call site.
- A date or a time is also read in a zone the caller names
  (`a-time-names-its-zone`).

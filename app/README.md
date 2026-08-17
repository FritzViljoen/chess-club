# app

The application. Server-rendered ERB on the Rails 8 defaults — Propshaft,
importmap, Turbo. No separate front end and no build step.

Rules that bind only part of this tree live in that part's own README —
[`models/`](models/README.md), [`controllers/`](controllers/README.md),
[`services/`](services/README.md).

## True of every file here

**Zeitwerk autoloads this tree, and the roots are the folders that hold Ruby — not
`app/` itself.** `app/controllers`, `app/controllers/concerns`, `app/helpers`,
`app/jobs`, `app/mailers`, `app/models`, `app/models/concerns` and `app/services`
are each a root;
`assets`, `javascript` and `views` are not autoloaded at all. So `app/models/y_z.rb`
defines `YZ`, and `app/models/concerns/y_z.rb` also defines `YZ` — neither folder
contributes to the constant. Nesting needs a directory that is *not* a root:
`app/models/billing/y_z.rb` defines `Billing::YZ`. Renaming a file renames a
constant.

**Identifiers use plain words**, never the vocabulary of the game — no `Match`, no
`draw`, no leaderboard, no "upset"
([`plain-words-in-code`](../docs/decisions/plain-words-in-code.md)).

**One way to say each thing.** Repeating an identical shape is fine; a second
spelling of the same operation is the defect, because every rule about that
operation then has to know both (principle → `one-way-to-say-each-thing`).

**Nothing fails quietly.** No rescue that swallows, no branch that returns a
plausible default instead of saying it could not do the work
(principle → `nothing-fails-quietly`).

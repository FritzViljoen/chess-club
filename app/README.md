# app

The application. Server-rendered ERB on the Rails 8 defaults — Propshaft,
importmap, Turbo. No separate front end and no build step.

What the application does is described in
[`../docs/domain/`](../docs/domain/). Rules that bind only part of this tree live
in that part's own README.

## True of every file here

**Zeitwerk autoloads this tree.** A file's path is its constant name, so
`app/x/y_z.rb` defines `X::YZ` and nothing else. Renaming a file renames a
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

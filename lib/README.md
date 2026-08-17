# lib

Code that belongs to no single folder under `app/`: the guards every domain
object shares, and the house RuboCop cops.

Rules that bind only part of this tree live in that part's own README —
[`rubocop/`](rubocop/README.md).

## True of every file here

**Nothing here knows the domain.** No record, no rule, no vocabulary from the
sport. What lives here would read the same in any application, which is the test
for whether it belongs here at all.

**Nothing here reaches back into `app/`.** These files are depended on; they do
not depend. A file here that names a class from `app/` is filed in the wrong
place (principle → `dependency-inversion`).

**A file here is documented at the top of itself.** What it is for, when to reach
for it, and what it deliberately does not do. Everything here is used from
somewhere else, so the file is the only place a reader will look.

## What it holds

| File | Holds |
|---|---|
| [`typed_arguments.rb`](typed_arguments.rb) | The type guards every service asserts its arguments with |
| [`boolean.rb`](boolean.rb) | The `Boolean` marker, so a flag argument can name one type |
| [`rubocop/`](rubocop/README.md) | The house cops. Loaded by RuboCop, never by the application |
| `tasks/` | Rake tasks |

# Plans

*How a [spec](../specs/) gets built, task by task.*

A plan turns an agreed design into ordered tasks, each ending in something that
runs and is tested. It is written for somebody who knows Ruby and nothing about
this repository, so it states the law each task is held to and shows the code
rather than describing it.

## Conventions

- **One piece of work per file**, named `YYYY-MM-DD-the-work-in-kebab-case.md`,
  matching the spec it implements.
- **A task is the smallest unit worth a reviewer's gate.** It carries its own
  test cycle and ends with a commit.
- **No placeholders.** "Add validation", "write tests for the above" and "similar
  to the task above" are plan failures — the engineer may be reading tasks out of
  order.
- **A plan is deleted when its work lands.** It describes how something was
  built, and only a decision record looks backwards
  (constitution → `documents-state-the-intended-shape`).

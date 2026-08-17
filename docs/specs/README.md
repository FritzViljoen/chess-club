# Specs

*The intended shape of a piece of work, agreed before it is built.*

A spec states what a change stores, derives and refuses, in enough detail that an
implementation plan can be written from it without a second conversation. It is
agreed before code is written and it is not a record of what was built.

A spec is not a [decision](../decisions/): where it makes a choice with a
defensible alternative, it names the decision record that choice needs, and the
reasoning lives there. A spec that outlives the work it describes has become
documentation of the system and belongs with the rest of it.

## Conventions

- **One piece of work per file**, named `YYYY-MM-DD-the-work-in-kebab-case.md`.
  The date is when the shape was agreed, which is the one thing about a spec that
  looks backwards.
- **Open questions are listed, not guessed.** Where a brief is silent, the spec
  rules so the code has one answer, and says under *Open questions* that the
  ruling is provisional.

# decisions-are-named-not-numbered — A decision is cited by its claim, never by a number

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV

## Context

The usual convention numbers decision records — `0001-…`, `0002-…` — and cites
them by number. The number has to be claimed before the file lands, which means
it is claimed on a branch. While that branch sits, the main line hands the same
number to something else.

This is not hypothetical. It has happened four times in a sibling project, the
last time straight through a written reservation that existed to prevent it. For
a period, citations in three other documents pointed at the wrong record
entirely.

## Decision

**A decision record is named after its claim, in kebab-case, and cited by that
name.** `no-nullable-columns.md`, not `0003-no-nulls.md`. There is no number, no
index to reserve against, and no ordering implied.

## Rationale

A name cannot collide by accident. Two branches that both invent
`no-nullable-columns.md` have written the same decision twice, which is a
conflict worth having — git surfaces it, and one of them is redundant. Two
branches that both take `0003` have written different decisions and git sees no
conflict at all.

A name also survives being moved, and reads correctly in prose: "per
`no-database-defaults`" tells the reader what is being cited before they open it.
"Per ADR 0004" does not.

## Trade-offs accepted

- **No chronology in the filename.** When a record was written is in git, which
  is a better answer than a number that only approximates it.
- **Renaming a decision breaks citations.** So the claim is settled before the
  file is named. A reversal supersedes; it does not rename.
- **Ordering has to be stated where it matters.** The table in
  [`README.md`](README.md) is ordered deliberately, foundations first.

## Consequences

- The index in [`README.md`](README.md) lists every record by name.
- A reversal adds a superseding record and marks the old one; neither is renamed.

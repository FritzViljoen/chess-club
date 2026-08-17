# Documentation

The written record: why this system is the way it is, what is true about it now,
and what was decided along the way.

## Where to start

| If you want | Read |
|---|---|
| How the code is built | [`principles.md`](principles.md) |
| The rules it must obey | [`constitution.md`](constitution.md) |
| Why a specific decision was made | [`decisions/`](decisions/) |
| What the app actually does | [`domain/`](domain/) |

## Three layers

A lower layer defers to a higher one on conflict.

1. **Principles** — how the code is built. Judgement, not rules. Nothing checks
   a principle and nothing can.
2. **Constitution** — the laws that carry the principles out. Each law names the
   principle it serves and the guard that holds it. A law with no guard says so.
3. **Decisions** — one claim per file, each carrying its full reasoning. A
   decision may refine a law; none may contradict the constitution.

Everything in these three layers is written in the present tense. They describe
what is true now, not what changed and when — why something changed belongs in
the decision that changed it.

## Two conventions

**Decisions are named, not numbered.** A file is `the-claim-in-kebab-case.md` and
that name is how it is cited. A number would have to be claimed before the file
lands, and two branches then claim the same one.
See [`decisions/decisions-are-named-not-numbered.md`](decisions/decisions-are-named-not-numbered.md).

**The ledger is append-only; everything else is edited in place.** A reversal
adds a new decision rather than rewriting the old one — the record of why a road
was closed is what stops it being walked again. The principles, the constitution
and the reference docs are corrected in place to match reality.

## A note on `CLAUDE.md` files

Most folders here carry both a `README.md` and a `CLAUDE.md`. The README is for a
person. The `CLAUDE.md` is the same ground compacted for an AI agent, which is
handed it automatically when it reads any file in that folder — and is handed
nothing else. They are kept in agreement deliberately. If they ever disagree,
the README is the source of truth.

`CLAUDE.md` files are not committed. They are working copies for whoever is
driving an agent, regenerated from these documents rather than maintained
separately.

# no-lifecycle-callbacks — No model registers an Active Record lifecycle callback

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Enacts:** constitution → `no-lifecycle-callbacks`

## Context

Active Record invites work to be hung off persistence: `before_save` to normalise a
field, `after_create_commit` to send mail, `after_destroy` to tidy up. It is the
path of least resistance, and each one reads as a small convenience at the point it
is written.

The cost is paid by the caller, who cannot see any of it. `member.save!` reads as
one operation and performs several, and the only way to find out which is to read
the whole class and every concern mixed into it.

## Decision

**No model may register a lifecycle callback**, and neither may a concern included
into one. Work belongs in a named method that says what it does, called where the
decision to do it is made.

`Model/NoCallbacks` enforces this over `app/models/**/*.rb` and fails CI.

## Rationale

Four things go wrong with a callback, and none of them is visible from the call
site.

**Order is implicit.** Two callbacks on the same event run in registration order,
which is an artefact of where they were typed. Nothing states the dependency
between them, so reordering the file changes behaviour.

**Every writer triggers it.** A fixture, a seed, a backfill and a console session
all go through `save`, so all of them run the mail send and the normalisation. The
usual workaround is a conditional on the callback, which is a second rule nobody
asked for.

**Testing the model in isolation stops being possible.** Constructing a record and
saving it now requires whatever the callbacks reach — a mailer, a job queue, another
table.

**The caller cannot see the work, so it cannot decide about it.** That is the real
objection: the decision to send mail belongs to the code that decided to create the
member, not to the act of writing a row.

## Trade-offs accepted

- **The caller has to remember.** `member.normalize_email` then `member.save!` is
  two lines, and forgetting the first is possible in a way a `before_save` is not.
  Where forgetting would be a defect rather than an inconvenience, the invariant
  belongs in the schema, which no caller can skip
  (principle → `the-schema-states-the-invariant`).
- **Some framework idioms are closed off.** `has_secure_password`,
  `touch: true` and counter caches all work through callbacks internally. Those are
  the framework's own, not ours; the rule binds callbacks we register.
- **More lines at each call site.** Deliberately: the lines say what happens.

## Consequences

- A model holds data, validations and named methods. Nothing runs on its own.
- Anything that must happen for several callers is its own object, called by each
  of them (principle → `one-decision-one-place`).
- `app/models/README.md` states the rule for anyone editing there.

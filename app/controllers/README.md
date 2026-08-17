# app/controllers

The HTTP seam. Each action collects input, calls one object, and renders.

## True of every file here

**No rule is decided here.** A controller does not compute, order, compare or
derive anything a caller elsewhere could need. It hands its input to the object
that owns the decision and renders what comes back
(principle → `one-decision-one-place`).

**Nothing here writes more than one object's worth of state.** Where an operation
touches several records, one object performs it in one transaction and the action
calls that (principle → `nothing-fails-quietly`).

**Every action names its permitted parameters.** No mass assignment from raw
params.

**Every parameter is parsed here, by `TypedParams`, and never inline.** A string
someone typed becomes a Date, an Integer or a boolean at this seam or nowhere:
past it, an operation is handed real values and asserts them
(constitution → `untrusted-input-is-parsed-at-the-seam`).

**A date or a time is read in a zone the action names**, passed to the parser as
`time_zone:`. There is no default and `Time.zone` is never the answer — a time an
hour out looks right, which is the failure this house designs out
(constitution → `a-time-names-its-zone`).

**A failure is rendered, not swallowed.** An action that cannot do the work says
so; it does not redirect to a page that implies it succeeded.

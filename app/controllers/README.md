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

**A failure is rendered, not swallowed.** An action that cannot do the work says
so; it does not redirect to a page that implies it succeeded.

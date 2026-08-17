# app/views

What a person looking at the application sees.

## True of every file here

**This is the one place the game's own words are used.** Elsewhere in `app/` an
identifier uses plain words — a `Person`, a `Contest`, the `standings`
(constitution → `plain-words-in-code`). Templates say **member**, **match**,
**draw**, **rank**, **games played**, **leader board**, because the people using
this are a chess club. The cop covers `app/**/*.rb`, so `.erb` is outside it by
construction, not by oversight.

**Do not carry the screens' vocabulary back into a service, a model or a
controller**, and do not "correct" a template to match the code.

**Nothing here decides anything.** A view formats what it was handed. Reading a
value off a record it was given is formatting; working one out is not.

**A partial derives what it can from what it is given**, rather than taking an
argument the caller would compute from an object already being passed.

**Shared partials live in `application/`** and are rendered by name from any
folder. They may not query.

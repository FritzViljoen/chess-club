# app/models

Records and the rules that belong to a single record.

## True of every file here

**A default value is decided here.** No column carries a database default
(constitution → `no-database-defaults`), so a starting value appears in the model
or nowhere.

**No attribute is ever absent.** No column in this schema is nullable
(constitution → `no-nullable-columns`), so a `&.`, a `.presence` or an "unknown"
branch means either the schema or the code is wrong.

**A validation is not the invariant.** It is advice to a form. What makes a rule
true is the constraint in the schema, and a model rule that matters has one
(principle → `the-schema-states-the-invariant`).

**A rule shared by more than one caller does not live here.** A model holds what is
true of one record. A decision that spans records, or that two callers need, is its
own object (principle → `one-decision-one-place`).

**No lifecycle callback, ever.** No `before_save`, `after_create`, `after_commit`,
`after_find` or any sibling — not in a model and not in a concern included into one.
The rule is absolute, not a judgement about whose work it is: persisting is not the
place to run anything, so the caller runs the rule and then persists
(constitution → `no-lifecycle-callbacks`, guarded by `Model/NoCallbacks` over
`app/models/**/*.rb`, which fails CI).

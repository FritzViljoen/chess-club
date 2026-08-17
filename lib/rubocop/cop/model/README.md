# lib/rubocop/cop/model

Cops policing models. Each is scoped to `app/models/**/*.rb` and fails CI. What each
cop forbids is documented at the top of its own file, and the rules as a model author
meets them are in [`../../../../app/models/README.md`](../../../../app/models/README.md).

## True of every file here

**Scope includes concerns.** A concern mixed into a model is model code, and a rule that
did not reach `app/models/concerns/` would be avoidable by moving the offending line one
folder across. The `Include` glob is `app/models/**/*.rb` for that reason.

**Framework internals are not in scope.** `has_secure_password`, `touch: true` and
counter caches are implemented with the same mechanisms these cops forbid. A cop here
matches what a model *registers*, not what the framework does on its behalf.

**A cop here matches the declaration, not its intent.** Whether the work in a
callback was reasonable is a judgement no cop can make; that it was hung off
persistence is a fact one can. A rule needing the former is not a cop — it is a
sentence in review.

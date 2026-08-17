# app/services

Every operation the application performs. One service, one operation, one public
method — `call`.

## True of every file here

**Every argument is type-checked where it arrives.** A hand-written `initialize`
passes each keyword through a `TypedArguments` guard, and a wrong type raises
(constitution → `arguments-are-typed-at-construction`).

**So nothing below the initializer re-checks an argument.** No nil guard, no
parse, no rescue for a value that arrived wrong. A failure at the guard is the
caller's defect; a failure after it is this service's.

**A time argument carries its zone.** It is asserted as an
`ActiveSupport::TimeWithZone`; naming `Time` or `DateTime` as the type is refused,
because an offset nobody chose is not a type worth asserting. A wall-clock
reading that is not a moment — a local pick-up time — is a String
(constitution → `a-time-names-its-zone`).

**`call` returns a `Result`, always.** `Service.call` raises `TypeError` on
anything else, so a caller can read `success?` without first checking what it was
handed (constitution → `a-service-returns-a-result`).

**Reading and writing are separate services.** A service that answers a question
does not also change something, and neither takes a flag to decide which it is
doing this time. The two are told apart by their names and by what they do, not
by two base classes (principle → `single-responsibility`).

**A refusal is a code, not a sentence.** `failure(:already_archived)`. The wording
belongs to whatever renders it — a page, a JSON body, a log line. A defect is not
a refusal: it raises.

**A change that spans records is one transaction.** Either all of it happened or
none of it did (principle → `nothing-fails-quietly`).

**Nothing here knows about HTTP.** No params, no session, no rendering, no
redirect. A service takes values and answers with a result, so the next caller
can be a job, a task or a test (principle → `dependency-inversion`).

**A rule that two callers need lives here, not in a model or an action.** That is
what this folder is for (principle → `one-decision-one-place`).

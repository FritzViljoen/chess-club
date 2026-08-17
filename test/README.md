# test

Minitest, the Rails default. `bin/rails test` runs the suite; `bin/ci` runs it
alongside everything else the build runs.

## True of every file here

**The tree mirrors what it tests.** A test for `x/y.rb` is at `test/x/y_test.rb`.

**A guard needs a test that proves it fires.** Delete the guard and the test must go
red; one that passes either way is coverage in name only
(principle → `make-the-wrong-thing-impossible`). Anything that rejects input is
tested in both directions — the rejection and the acceptance.

**The object that owns a rule is tested directly.** A rule reached only through a
request is tested through three layers of noise, so its own test constructs the
object and calls it (principle → `one-decision-one-place`).

**An invariant is asserted after the operation, never assumed.** Where a shape is
guaranteed, a test states it and checks it still holds once the work has run.

**A failing assertion says what produced it.** The message carries the input, not
just the two values that differed.

**Names and identifiers use plain words**, never the vocabulary of the game
([`plain-words-in-code`](../docs/decisions/plain-words-in-code.md)). A test name
describes the situation, not a term of art.

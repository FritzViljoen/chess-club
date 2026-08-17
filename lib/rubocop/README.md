# lib/rubocop

House RuboCop cops — the guards that hold the laws a machine can check. Every cop
here fails CI, so a rule that lives in this folder is enforced rather than
remembered (principle → `make-the-wrong-thing-impossible`).

What each cop forbids is documented at the top of that cop's own file, and why it
exists is in [`../../docs/decisions/`](../../docs/decisions/).

## True of every file here

**One folder per subject, one cop per file, one loader per folder.** `<subject>.rb`
requires everything in `cop/<subject>/`. `.rubocop.yml` requires the loaders, never
the cops, so adding a cop needs no change to a loader — only its own `Enabled` and
`Include` entry in the config.

**The namespace names the subject, not this application.** `Schema`, `Model`,
`Vocabulary` — never
the name of the app. These rules are about Rails and about databases; nothing in
them is specific to a chess club (constitution → `plain-words-in-code`).

**A cop's file is its documentation.** The rule, the reason for it, and an
`@example` block showing the bad and good forms all sit at the top of the cop. A
rule that cannot be stated in a paragraph there is more than one rule.

**Recognition shared by two cops lives in the subject's module**, never copied
between them (principle → `one-decision-one-place`).

**Every cop is tested in both directions** — it flags the bad form *and* accepts the
good one. A cop tested only on offenses passes just as well once it has stopped
matching anything (principle → `make-the-wrong-thing-impossible`). Tests are in
[`../../test/lib/rubocop/`](../../test/lib/rubocop/).

**Scope is configuration, not code.** Where a cop applies is an `Include` in
`.rubocop.yml`; a path check inside the cop is not how it is done.

**Never define a method that `RuboCop::Cop::Base` already defines.** A cop is a
subclass, so a private helper silently replaces the framework's method of the same
name and the failure has no error attached to it. `relevant_file?`,
`excluded_file?`, `message` and `cop_config` are the ones within reach of a helper
you would plausibly write. Check with
`RuboCop::Cop::Base.private_instance_methods(true).include?(:name)` before adding
one.

**This folder is not autoloaded.** `lib/rubocop` is excluded from
`config.autoload_lib` — the cops live under the `RuboCop` namespace, which Zeitwerk
reads as `Rubocop` and refuses to load, and they have no business inside the running
app.

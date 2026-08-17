# ci-is-one-command — CI runs `bin/ci` and nothing else

- **Status:** Accepted
- **Date:** 2026-08-17
- **Deciders:** FV
- **Enacts:** constitution → `ci-is-one-command`

## Context

Rails 8.1 generates two things that overlap. `config/ci.rb` defines a list of
steps run by `bin/ci` — style, gem audit, importmap audit, Brakeman, tests, seeds.
The GitHub Actions template defines the same steps again as separate jobs, in
YAML.

Two lists mean two truths. A step added to one is missing from the other, and the
gap shows up as a build that passes locally and fails on the branch, or worse, the
reverse.

## Decision

**The workflow's only step is `bin/ci`.** The step list lives in `config/ci.rb`
and nowhere else. A green `bin/ci` locally is the same set of checks the build
runs.

## Rationale

This is `one-way-to-say-each-thing` applied to the build. The value is not the
saved YAML; it is that a developer can reproduce a red build exactly, with one
command, without reading the workflow file to find out what it ran.

The generated multi-job template buys parallelism — style, audits and tests run at
once, so the wall clock is the slowest job rather than the sum. At this size the
whole suite is about forty seconds, so the parallelism saves nothing worth a
second list.

## Trade-offs accepted

- **No per-step reporting in the GitHub UI.** A failure shows as "CI failed" and
  the step is in the log rather than in a job name. Acceptable while the log is
  short; if it stops being short, the fix is to make `bin/ci` report better, not
  to split the workflow.
- **No parallelism.** Bought back cheaply if it ever matters.
- **Serial failure.** `bin/ci` stops at the first failing step, so one run may not
  surface every problem. That is also how it behaves locally, which is the point.

## Consequences

- Adding a check means adding a line to `config/ci.rb`; the workflow does not
  change.
- The workflow file is short enough to read at a glance, which is what makes the
  claim above verifiable.
- Draft pull requests still trigger the build — `pull_request` fires on drafts. If
  idle drafts are wanted, that is a guard on the job, not a change to this
  decision.

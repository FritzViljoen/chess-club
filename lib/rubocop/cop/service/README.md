# lib/rubocop/cop/service

Guards over `Service`, the base every operation inherits.

## True of every file here

**Scope is by base class, not by folder.** A cop here recognises its subject by
what the class inherits, so a service is held to the rule wherever the file is
filed. `.rubocop.yml` offers it the whole of `app/`; the cop decides.

**A namespaced base is the same base.** `Rounds::Service` is a `Service`. A cop
that compared the full constant path would go quiet the first time a service was
namespaced, which is the failure mode a guard must not have
(principle → `nothing-fails-quietly`).

| Cop | Forbids |
|---|---|
| `Service/NoUnguardedArguments` | An initializer keyword that no `TypedArguments` guard asserts |

# lib/rubocop/cop/controller

Guards over the HTTP seam.

## True of every file here

**These cops are about what a controller is not allowed to do itself.** The seam
collects input, calls one object and renders; a cop here fires when work that
belongs to something else has been written into an action instead.

**Scope is `app/controllers/**`, set in `.rubocop.yml`.** A cop here does not
check its own path (`lib/rubocop/README.md`).

| Cop | Forbids |
|---|---|
| `Controller/NoInlineParamParse` | Parsing a request parameter inline instead of through `TypedParams` |

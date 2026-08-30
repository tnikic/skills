---
name: grill-with-docs
description: A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go.
disable-model-invocation: true
---

Run a `/grilling` session, using the `/domain-modeling` skill (pattern: [`grilling-with-domain-modeling.md`](../../shared/grilling-with-domain-modeling.md)).

This is a discussion: the only files you write are `docs/CONTEXT.md` and
`docs/adr/`, and it ends in a plan. Read the shared
[`continuation`](../../shared/continuation.md) reference when the plan reaches
its boundary; the exact route stays in the agent interaction while public
records describe the work and decisions.

## Route the plan

Return the complete continuation set from the delegated `/grilling` session.
The shared continuation contract owns route selection, including the
one-ticket, multi-ticket, too-large, and deliberate-stop branches.

## During the session

Watch for signals that the discussion is outgrowing a single session:

- **Deferral language** — the user says "let's come back to this," "we'll figure that out later," or explicitly defers a thread.
- **Accumulating threads** — 3 or more unresolved threads pile up without resolution.

When either fires, offer: "This is getting large — want me to create a Wayfinder map to track these threads across sessions?" If the user says yes:

1. Delegate to `/wayfinder` to create a stub map — pass it the destination, domain, skills, preferences, and raw unresolved threads. Wayfinder owns the stub format and will create the `kind:map` issue.
2. Tell the user to run `/wayfinder` on the new map — Wayfinder will clean up the body and chart tickets properly.

## Ending the session

When the grilling session concludes, stage all domain-modeling changes (`docs/CONTEXT.md`, `docs/adr/`) and run `/commit`.

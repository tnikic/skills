# Issue Template

Canonical template for agent-grabbable tickets. Used by the pipeline stages that create and consume tickets: `to-tickets` (creates), `implement` and `triage` (consume).

```markdown
## What to build

The end-to-end behaviour this ticket makes work, from the user's perspective — not layer-by-layer implementation.

**Review impact:** critical | high | normal | low (omit to default to normal)

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

- A reference to each blocking ticket, or "None — can start immediately".
```

Avoid specific file paths or code snippets — they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

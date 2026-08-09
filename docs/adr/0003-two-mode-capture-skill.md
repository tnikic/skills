# Two-mode /capture skill: forensic bugs, lightweight ideas

`/capture` is the front door into the ticket pipeline (`triage` → `to-tickets` → `implement`). It has two modes, differentiated at invocation:

- **Bug**: auto-captures forensic detail — OS, shell, last command, error output, tool version — plus the user's description of what happened, what was expected, and what worked before (the delta). Sensitive data is stripped via pattern matching and agent judgment.
- **Idea**: captures the user's description as-is, lightweight.

Both apply `triage:pending` + the appropriate `type:*` label (inferred from invocation), and file on a target repo specified in natural language ("for owner/repo" or "on this repo"). User-invoked only — no ambient detection.

The trade-off was between a single generic capture (simpler but less useful to triage) and typed capture with auto-forensics (more structure upfront, but triage gets everything it needs to reproduce without asking).

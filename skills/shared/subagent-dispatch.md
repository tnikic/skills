# Subagent Dispatch

The **subagent** tool delegates work to isolated agents. This file is the single source of truth for the dispatch pattern — how to brief, spawn, collect, and report. Skills that dispatch subagents point here rather than restating the mechanics.

## When to dispatch

- Work is **independent** of the current context (no shared state to pass back and forth)
- The subagent needs **different source material** than the calling skill already loaded
- Multiple checks can run in **parallel** without interfering (e.g., three review axes)
- The work is **read-only research** — investigation against primary sources

## The pattern

### Brief

Give each subagent a self-contained brief. Include:

- **The exact task** — what to produce, in what format
- **All source material** — diff, spec contents, file paths, taxonomy, standards. The subagent has no access to the caller's context
- **A word limit** — e.g. "Under 400 words." Keeps the subagent focused
- **The agent name** — pick the right agent per task type:
  - `researcher` — fact-finding and investigation (tool research, documentation spelunking, wayfinder research tickets)
  - `auditor` — analysis, judgment, and compliance checking (code-review axes, standards conformance, spec verification)
  - `architect` — structural analysis and interface design (codebase exploration, design-it-twice, architecture review)
  - `worker` — implementation from a predefined plan or ticket (the execution lane; it dispatches auditor(s) to review its own work)

Do not rely on the subagent having any knowledge of the project structure — pass it everything it needs.

For research subagents, add: investigate against **primary sources** — official docs, source code, specs, first-party APIs — not secondary write-ups. Follow every claim back to the source that owns it. Save findings where the repo keeps such notes; if no convention exists, use `docs/research/<topic-slug>.md`.

### Spawn

- **Parallel when independent.** If N tasks don't depend on each other, fire them in one message with N `subagent` calls. They run concurrently.
- **Sequential when dependent.** If task B needs the output of task A, use `chain` mode with `{previous}`.

### Collect

The subagent returns its findings. The caller:

1. Reads each subagent's output
2. Aggregates under headings (don't merge or re-rank — keep axes separate when they're separate)
3. Reports verbatim or lightly cleaned

### Cleanup

- If the subagent created a local branch, delete it after capturing findings in the comment or report.
- Delete any files the subagent created (e.g. `docs/research/<topic>.md`) — the comment or report is the canonical record.
- Branches stay local — never push them.

## Anti-pattern

Don't nest dispatches: one skill fires a subagent that itself fires another subagent. Cut the middle layer — call `subagent` directly with the brief.

**Carve-out: worker → auditor.** The worker agent (depth 1) dispatches auditor subagent(s) (depth 2) to review its own work. This is depth-2 by design, not the redundant relay the anti-pattern targets — the worker owns the implementation being reviewed, so there is no middle layer to cut.

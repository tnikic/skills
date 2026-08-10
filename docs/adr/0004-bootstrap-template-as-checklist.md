# Bootstrap template as checklist, not blueprint

The bootstrap skill uses a hybrid generation strategy: template fragments for stable structure (target names, CI skeleton), agent-resolved decisions for dynamic parts (tool versions, linter config). On re-run, the template acts as a checklist of what should exist — the agent diffs against it and fills gaps only, never removing content that was intentionally added by a previous session. This was chosen over two alternatives: full overwrite on every run (destroys intentional customizations) and marked regions (adds file-format complexity and visual noise). The "add only, never remove" rule means the agent treats user-added sections as intentional and preserves them, while still keeping project infrastructure up to date.

## Considered Options

- **Full overwrite** — simple but destroys user customizations. Rejected: too destructive for re-runs.
- **Marked regions** (`# --- bootstrap:X ---`) — safe but adds comment clutter and imposes a file format constraint. Rejected: user found the visual noise unacceptable.
- **Template as checklist** — diff-driven, fills gaps only. Chosen: safe by default, no file-format constraints, respects intentional additions.

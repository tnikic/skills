# Keep research external and prototypes disposable

Canonical research records live in the stable per-user XDG cache, with issue-backed findings recorded in the developer-facing owner record. OS temp is reserved for scratch material. Project-local prototype residue is permitted while a design question is being tested but must be removed before the prototype workflow completes, unless validated content is promoted into the project. This keeps research revisitable without repository pollution and keeps prototypes from becoming accidental production dependencies.

## Considered Options

- **Store research in the repository** — rejected: research is supporting evidence, not production project content.
- **Use OS temp as the canonical record** — rejected: it may be purged between sessions.
- **Leave prototypes in the project after evaluation** — rejected: throwaway experiments would become unmarked production surface.

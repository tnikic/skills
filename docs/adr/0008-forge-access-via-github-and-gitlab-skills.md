# Forge access via github and gitlab skills

All forge access from skills routes through two model-invoked skills — `github` (backed by the `gh` CLI) and `gitlab` (backed by the `glab` CLI) — that document exact command recipes for every forge action (issues, labels, comments, issue hierarchy, assign, close/reopen, PRs, repo create/delete/list, auth), so the agent spends its effort interpreting results, not deriving commands.

## Considered Options

- **Split by API (REST vs GraphQL)** — rejected: two skills with identical feature breadth; the API mix is an implementation detail of `gh`/`glab` (they already blend both), not a capability the agent needs to choose between.
- **Split by domain (tickets vs repos/PRs)** — rejected: leaves the split implicit and forces the model to decide per action.
- **One generic "harness" tool** — rejected: existing skills already say "the harness provides the operations"; the two skills make the operations concrete and reusable.
- **Gitignored `skills/generated/` location** — rejected: hand-authored skills should be committed under `skills/engineering/` so they are versioned and pass the Makefile lychee and label-taxonomy gates.

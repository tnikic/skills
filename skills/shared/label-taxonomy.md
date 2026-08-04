# Label Taxonomy

Every label on the issue tracker belongs to exactly one scope. Within a scope, labels are exclusive — one per issue. This file is the single source of truth for every scope, its values, and its color token.

| Scope | Value | Color token | Description |
|-------|-------|-------------|-------------|
| `triage` | `pending` | `secondary` | Maintainer needs to evaluate |
| `triage` | `unanswered` | `secondary` | Waiting on reporter for more information |
| `triage` | `for-agent` | `secondary` | Fully specified, ready for an AFK agent |
| `triage` | `for-human` | `secondary` | Needs human implementation |
| `triage` | `wontfix` | `secondary` | Will not be actioned |
| `type` | `bug` | `primary` | Something is broken |
| `type` | `enhancement` | `primary` | New feature or improvement |
| `kind` | `spec` | `surface` | Planning document with problem, solution, and user stories |
| `kind` | `ticket` | `surface` | Single unit of agent-sized work |
| `kind` | `map` | `surface` | Wayfinder planning map |
| `kind` | `decision` | `surface` | Question whose resolution is a decision |
| `wayfinder` | `research` | `accent` | AFK: investigate facts against primary sources |
| `wayfinder` | `prototype` | `accent` | HITL: build a throwaway artifact to react to |
| `wayfinder` | `grilling` | `accent` | HITL: stress-test a decision via interview |

Color tokens are defined in [`color-palette.md`](color-palette.md).

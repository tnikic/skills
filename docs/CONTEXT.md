# Context

Glossary of domain terms for the agent skills ecosystem.

## Skills

- **bootstrap** — Skill that aligns any repo to the standard project shape (Makefile/justfile, CI, pre-commit hook, README) using a language profile.
- **commit skill** — Universal choke point that gates quality (lint, fmt, typecheck) and docs (freshness check) before any `git commit`. Calls `conventional-commits` for the message.
- **capture** (`/capture`) — User-invoked skill for filing bugs (forensic auto-capture) or ideas (lightweight) into the ticket pipeline. Front door to `triage` → `to-tickets` → `implement`.
- **handoff** — Named invocation point for compacting the current session into a handoff document for a fresh agent. Used at context-limit boundaries.
- **tdd** — Skill for test-driven development. After the skills refactor (map 31): feedback-first framing — runnable check before code, smallest provable slice first, E2E as final gate. Test list as transient external state. Cheating defenses. Refactoring in green only.
- **github skill** — Model-invoked skill for GitHub forge actions, backed by the `gh` CLI. Authoritative command-recipe catalog for GitHub.
- **gitlab skill** — Model-invoked skill for GitLab forge actions, backed by the `glab` CLI. Authoritative command-recipe catalog for GitLab.

## Forge access

- **forge action** — An operation against a git forge: creating, viewing, commenting, editing, closing, reopening, assigning issues; applying labels; PR operations; repository create/delete/list.
- **command recipe** — An exact CLI invocation (tool, flags, args) documented for a forge action, so the agent runs it directly instead of deriving it. The unit of the github and gitlab skills.
- **model-invoked** — A skill the model picks up automatically from its description, not only when the user explicitly invokes it.
- **issue hierarchy** — Parent/child and blocked-by/blocking relationships between tickets; queried by wayfinder, to-tickets, and implement.
- **ticket pipeline** — capture → triage → to-tickets → implement; the journey of a bug or idea to a merged change. Front door is `capture`.

## Conventions (TDD)

- **feedback-first** — The agent needs a runnable pass/fail check before code, at the smallest provable slice; E2E/acceptance is the final gate, never the first step. Replaces type-first framing (unit tests first, E2E trailing).
- **smallest provable slice** — The thinnest runnable vertical check through real seams that proves a ticket's slice works (one request, one assertion, happy path). Not a full E2E browser test; not a mocked unit test.
- **test list** — Transient external state (`test-list.md`) listing the tests to write, derived from a ticket's acceptance criteria. Drives ordering one test at a time; prevents coding ahead and cheating. Never committed — the skill carries an explicit delete rule: the committed tests are the record, the plan file is deleted when the ticket is done (mirrors the research-dispatch cleanup pattern).
- **test concern** — A coherent contract boundary for executable repository validation: repository/Makefile/CI contracts, skill/workflow contracts, or forge-adapter contracts.
- **modular repository test suite** — The executable test suite organized by test concern behind the unchanged `make test` entrypoint, with deterministic execution and concern-specific diagnostics.
- **test parity** — Evidence that modularization preserves the existing suite's assertions and failure semantics by inventorying each assertion, mapping it to a concern, and running the complete offline suite.
- **cheating defenses** — Agent anti-patterns: deleting/disabling a red test to pass, "looks done" without a run, coding ahead of the test list, authoring mocks so a test passes trivially.
- **test-first pairing** — Escalation pattern: for larger slices or long runs, dispatch a separate agent to write tests and another to implement to pass them. Not the default; coverage review already provides post-hoc fresh-context scrutiny.

## Shared modules

- **command-runner** — Single source of truth for detecting and invoking the project's command runner (Makefile or justfile). Skills that need to run project targets read from here rather than reimplementing detection.
- **issue-template** — Canonical template for agent-grabbable tickets (`## What to build`, `## Acceptance criteria`, `## Blocked by`). Used by `to-tickets` (creates), `implement` and `triage` (consume).
- **pr-template** — Canonical template for PR bodies (`## What this does`, `## Changes`, `## Acceptance criteria` mirrored from the ticket, `Closes #N` footer). Sibling of `issue-template`; PR is a thin projection of its ticket. `Closes #N` lives here, never in the commit message.

## PR-based workflow

- **PR-based workflow** — Work lands via PR, not direct push to main: `implement` pushes a feature branch and opens a PR; CI gates the merge, not the commit. Replaces the old push-and-close flow where CI ran after a closed ticket left a broken main.
- **PR handoff** — After local gates, pre-PR Standards and Spec review, `/commit`, and the final test pass, `implement` pushes the branch and opens the PR. It requires an explicit `HUMAN_REVIEWER`, requests review, transfers ticket assignment at handoff, and leaves the PR and ticket open.
- **fleet manager** — Future skill that spawns subagents to run `implement` in parallel across unblocked tickets, using worktrees so branches do not interfere. Owns merge ordering and renumbers PR titles when the set changes. Too big for one decision ticket; charted separately.
- **stacked PRs** — A chain of PRs where each targets the branch of the one below it, so overlapping work lands bottom-up. Native in GitHub (`gh stack`, public preview 2026) and GitLab (stacked MRs); the forge handles rebase, retargeting, and merge order — not reimplemented by skills.
- **PR title numbering** — `[<slug> <n>/<N>]` prefix on PR titles: slug groups a spec's PRs in the list view, n is merge position (stack depth; same-n merge in any order), N is the spec's ticket count (stable). `implement` stamps a provisional n at PR-open; the fleet manager normalizes after the run settles and after deletions.
- **Conventional Branch** — The `<type>/<description>` branch-naming spec (v1.1.0) adopted for agent-created branches; inspired by Conventional Commits, ships a machine-readable `spec.json` with the authoritative validation regex and enforcement configs (GitHub rulesets, GitLab push rules, pre-push hook, AGENTS.md snippet).
- **branch naming convention** — Per-ticket branch: `<type>/<ticket-number>-<spec-slug>` (e.g. `feat/42-pr-workflow`); combined single-spec branch: `<type>/<spec-slug>` (e.g. `feat/pr-workflow`). Type is a Conventional Branch purpose prefix mapped from the ticket's dominant commit type (`chore/` fallback; `refactor/` as a documented team extension). `n/N` merge-order numbers ride in PR titles only, never in branches.
- **spec slug** — Kebab-cased spec name used as the branch description and the PR-title slug; the single source of naming for a spec's branches and PRs, so the branch and PR title always agree.
- **ready for review** — The state where the agent's work on a PR is done: the branch is pushed, the PR is open, every required check passes for the exact current PR head SHA, and conflicts are resolved. Optional checks remain informational. `implement` hands it over by assigning the ticket to the human; the human reviews from here and merges; the agent never merges.
- **exact-head readiness** — Readiness is evaluated only after `get_pr` records the current head SHA, required checks are discovered, and `status_for_head` reports success for that exact current PR head SHA. A newer head invalidates the result, and a missing required-check configuration is a configuration gap rather than success.
- **merge** — Human-only step in the PR-based workflow: the human reviews the PR in the forge UI and merges (squash). Issue closes at merge-to-main.
- **merge-conflict sweep** — After any merge to `main`, every open PR is checked for conflicts against the new head; stale or conflicted branches are rebased and re-CI'd before they can be reviewed again. Owned by merge-conflict repair and the fleet manager.
- **merge-conflict repair** — Policy-driven maintenance of an open PR after its branch becomes stale or conflicts with the current base. It rebases in an isolated worktree, resolves only clear in-scope conflicts, reruns checks and CI, and leaves semantic ambiguity for the human.
- **repair agent** — Dedicated agent dispatched by the fleet manager to run merge-conflict repair. It preserves the PR-review ticket state; it is not a fresh implementation run.
- **review-analysis skill** — The skill that processes review comments on PRs: classifies each comment by commenter identity (trusted operator vs external), analyzes intent, grills the human for clarity on ambiguous trusted comments, and orchestrates the response via `implement`. For external comments it summarizes without acting; for trusted comments with clear intent it acts directly. No closed-unmerged fallback — PRs are not closed by the human, and case-by-case handling is never a skill-built-in.
- **pre-PR code review** — The mandatory agent review performed by `implement` before opening a PR. It always runs Standards and Spec; Coverage is not part of normal implementation and is owned exclusively by `improve-codebase-architecture`. Its findings and routine corrective edits are an internal quality gate, not PR content, unless quality improvement is the ticket's subject.
- **pre-PR implementation loop** — The bounded workflow from the initial local check through pre-PR review, corrective checks, final test, and commit gate. Mechanical review corrections stay within the loop; new user intent starts a fresh review decision.
- **history-in-tracker** — Decision history and rationale live in the issue tracker — issues, PRs, and comment threads; only ADRs and CONTEXT.md are written to the repo. The review-analysis skill treats human comments as the record and acts on them without inventing separate spec docs.
- **PR impact** — How much review attention a PR warrants: security criticality of the files touched, size and breadth of the change. Distinct from priority (urgency/order). A label scope (`impact:critical|high|normal|low`, `normal` default) declared by the spec per ticket and applied to the PR by `implement` at open. Pure review triage — never gates merge.
- **label-taxonomy** — Single source of truth for every label scope, value, and color token. Also carries the usage instruction (how to pass `--color`).
- **color-palette** — Hex values for every color token referenced by the label taxonomy.

## Artifacts

- **language profile** — Per-ecosystem catalog of tools, conventions, and constraints (e.g., Go: golangci-lint, gofumpt via go tool, Makefile). Consumed by bootstrap and CI generation. Not hardcoded commands — declares what to use and constraints; the agent resolves invocation.
- **base profile** — Fallback language profile for languages without a dedicated profile. Carries language-agnostic defaults (generic CI, README); no ecosystem-specific tooling.

## Conventions

- **Makefile/justfile** — Ecosystem-native command runner, single source of truth for tooling. Go uses Makefiles; Rust uses justfiles. Standard targets: `check` (lint, fmt, typecheck), `test` (full suite and vulnerability scan), `lint`, `fmt`. Agent `code-review` is a separate workflow stage, not part of either target.
- **pre-commit hook** — Dumb mechanical gate that runs `make check`. Fast, no agent needed.
- **CI pipeline** — Agent-generated from language profile. Runs the project's `check` and `test` targets. Not a hardcoded template — the agent renders it fresh, researching latest versions.
- **version pinning rule** — Always research the latest stable version before pinning any dependency (GitHub Actions, SDKs, tools). Training data is stale; primary sources are current.

## Gates

- **quality gate** — Enforced at two points: fast local `make check` (pre-commit hook) as feedback, and the authoritative **merge gate** in CI. Hard block — failures block commit locally and merge upstream.
- **docs gate** — Agent check: does the diff invalidate any existing doc file (README, CONTRIBUTING, CHANGELOG)? Auto-updates. Runs pre-commit for feedback and as an agent step at PR-open/update under the PR-based workflow. Hard block.
- **merge gate** — The authoritative gate at the merge barrier: CI runs `make check` + `make test` on the PR head, required and green on latest-on-branch; a stale or failing check blocks merge. Pre-commit checks are convenience, not the source of truth.
- **required CI check** — A forge status explicitly required by branch protection or rulesets. Every required check must pass before a PR is ready for review; optional checks remain informational. Missing required checks are a repository configuration gap, not an implicit pass.
- **CI head binding** — A CI result is valid only for the exact PR head SHA it observed. A newer branch commit invalidates older pending or passing results and requires checks on the new head.
- **CI failure classification** — A deterministic, branch-caused defect covered by the ticket specification may be auto-fixed; infrastructure, flaky, ambiguous, unrelated, or scope-expanding failures are handed to the human with evidence.
- **CI wait window** — The bounded period `implement` waits for required checks after PR creation or a branch update. It is configurable, with a 30-minute default; timeout leaves the PR open and not ready for review. Deterministic ticket-scoped failures may be repaired for at most two cycles; infrastructure, flaky, ambiguous, unrelated, and scope-expanding failures remain with the human.
- **universal commit gate** — Any skill that produces a commit goes through the `commit` skill. No single skill owns code changes; the gate owns them.

## Repository References

- [PR delivery contracts](../skills/shared/pr-delivery-contracts.md) define branch names, delivery modes, titles, impact labels, and lifecycle.
- [PR template](../skills/shared/pr-template.md) defines the projected handoff body and `Closes #N` footer.
- [Issue template](../skills/shared/issue-template.md) defines agent-ready ticket structure and acceptance criteria.
- [Label taxonomy](../skills/shared/label-taxonomy.md) and [color palette](../skills/shared/color-palette.md) define tracker vocabulary.
- [Command runner](../skills/shared/command-runner.md) defines `make` or `just` target detection.
- [PR-head binding ADR](adr/0014-ci-results-bind-to-pr-head.md) records exact-head readiness and failure boundaries.
- [Review identity ADR](adr/0016-review-comments-have-an-identity-boundary.md) records trusted and external commenter handling.
- [Merge-conflict repair ADR](adr/0015-dedicated-merge-conflict-repair.md) records isolated rebase repair and ticket-state preservation.

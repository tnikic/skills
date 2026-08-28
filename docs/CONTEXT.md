# Context

Glossary of domain terms for the agent skills ecosystem.

## Skills

- **bootstrap** — Skill that aligns any repo to the standard project shape (Makefile/justfile, CI, pre-commit hook, README) using a language profile.
- **commit skill** — Universal choke point that gates quality (lint, fmt, typecheck) and docs (freshness check) before any `git commit`. Calls `conventional-commits` for the message; execution stays here.
- **capture** (`/capture`) — User-invoked skill for filing bugs (forensic auto-capture) or ideas (lightweight) into the ticket pipeline. Front door to `triage` → `to-tickets` → `implement`.
- **handoff** — Named invocation point for compacting the current session into a handoff document for a fresh agent. Used at context-limit boundaries.
- **tdd** — Skill for test-driven development. After the skills refactor (map 31): feedback-first framing — runnable check before code, smallest provable slice first, E2E as final gate. Test list as transient external state. Cheating defenses. Refactoring in green only.
- **github skill** — Model-invoked skill for GitHub forge actions, backed by the `gh` CLI. Authoritative command-recipe catalog for GitHub.
- **gitlab skill** — Model-invoked skill for GitLab forge actions, backed by the `glab` CLI. Authoritative command-recipe catalog for GitLab.
- **research** — Model-invoked workflow for primary-source investigation that leaves a cited research record in the stable per-user cache.
- **resolving-merge-conflicts** — Model-invoked workflow for tracing conflict intent, resolving hunks, running checks, and finishing through the commit gate.

## Workflow Model

**Workflow**:
A skill-led path that turns an idea, decision, or change into one or more durable artifacts and an explicit continuation.

**Primary artifact**:
The main durable result of a workflow. A workflow may also create downstream artifacts when the destination requires them.
_Avoid_: finishing product, final output

**Artifact set**:
The complete group of durable records produced by a workflow, including its primary artifact and any explicitly linked downstream artifacts.

**Implementation landscape**:
A small, issue-backed description of the implementation work that follows a design discussion. It may contain one implementation ticket or several related tickets.

**Continuation set**:
The ordered set of next actions a workflow exposes at its boundary. It may fan out into independent actions, such as publishing a spec now while recording non-blocking follow-up maps for later.

**Spec overflow**:
The exceptional condition where a spec exceeds the issue tracker's body limit. The spec remains one issue record; useful sections move into ordered comments rather than creating additional specs.

**Continuation**:
The explicit next skill or deliberate stopping point produced when a workflow reaches its current boundary. It is based on the artifact's state and destination, not merely on which skill just ran.
_Avoid_: handoff, next step

**Issue record**:
The issue-tracker entry that preserves the intent and history behind planned work, including work that is implemented immediately afterward.
_Avoid_: ticket (when referring to the record generically)

**Uncharted map**:
A follow-up Wayfinder map recorded for later pickup. It has a destination and unresolved threads but has not entered an active Wayfinder session. The current raw form called a "stub map" is an uncharted map.

**Charted map**:
A Wayfinder map currently being worked through its decision frontier.

**Decision ticket**:
A `kind:decision` child of a Wayfinder map that resolves one planning decision. A domain decision may also be captured in `docs/CONTEXT.md` or an ADR; those are not necessarily decision tickets.

**Implementation ticket**:
A bounded issue record whose acceptance behavior is settled enough for `/implement` to build without another planning branch.

**Spec**:
A durable, publishable description of a problem, solution, user stories, implementation decisions, testing decisions, and scope, intended to be broken into implementation tickets or used as the implementation handoff.

**Published spec**:
A spec that exists as a `kind:spec` issue record and is ready to enter the ticket-planning route. `kind:spec` does not describe work that merely still needs planning.

**Spec-ready**:
A planning state in which the known work can be expressed as one spec, while any remaining fog is either non-blocking or assigned to separate uncharted maps.

**One-ticket shortcut**:
The direct route from a planning workflow to `/to-tickets` when the agreed implementation landscape contains exactly one implementation ticket. It still creates an issue record before `/implement` runs.

**Owner**:
The workflow or artifact that requested a specialist activity and receives its findings or verdict. The owner controls whether that result advances to another continuation.

**Internal continuation**:
The agent-facing routing information used to choose a subsequent workflow. It belongs in the live session context, not in an issue body or comment.

**Developer-facing record**:
An issue body or comment written in terms of the work, decision, and outcome a developer needs to understand. It does not expose skill names or workflow procedure.

**Machine metadata**:
Tracker state, labels, assignments, and relationships used to query and coordinate work. Machine metadata may remain on an issue when the tracker requires it, but it is distinct from developer-facing prose.

**Planning hierarchy**:
The native issue structure in which a map owns decision work, a spec owns implementation tickets, and a map links to its resulting spec as an outcome rather than treating the spec as a map child.

**Research record**:
A cited, durable result of an investigation that can be revisited by the owning workflow without rerunning the research. Its storage must remain outside production source unless the research itself is intentionally part of the project.

**Research cache**:
The stable per-user XDG cache location for canonical research records. OS temp is reserved for disposable scratch material, while issue-backed findings are also recorded on the developer-facing owner record.

**Prototype residue**:
Temporary project-local files created to test a design question. They may be necessary while a prototype runs, but are removed after the verdict unless the validated result becomes real project content.

**Prototype cleanup**:
The completion step that removes prototype residue from the project path after the design verdict is captured, retaining only validated project content or an explicitly throwaway external copy.

**Intake record**:
The original issue record that preserves the user's intent and history while linked maps, specs, decisions, and implementation tickets carry the work forward.

## Forge access

- **forge action** — An operation against a git forge: creating, viewing, commenting, editing, closing, reopening, assigning issues; applying labels; PR operations; repository create/delete/list.
- **command recipe** — An exact CLI invocation (tool, flags, args) documented for a forge action, so the agent runs it directly instead of deriving it. The unit of the github and gitlab skills.
- **model-invoked** — A skill the model picks up automatically from its description, not only when the user explicitly invokes it.
- **issue hierarchy** — Parent/child and blocked-by/blocking relationships between tickets; queried by wayfinder, to-tickets, and implement.
- **forge hierarchy capability** — The forge-specific mapping behind the shared issue hierarchy: GitHub uses child issues, while GitLab uses task work items parented under issues. Consumers use the matching forge recipe rather than assuming one issue type.
- **ticket pipeline** — capture → triage → to-tickets → implement; the journey of a bug or idea to a merged change. Front door is `capture`. Other planning routes can enter the pipeline through `/grilling`, `/wayfinder`, or `/to-spec`.
- **small-work route** — `/grill-with-docs` → `/to-tickets` → `/implement`; the normal path when grilling settles exactly one bounded implementation ticket.
- **multi-ticket route** — `/grill-with-docs` or `/wayfinder` → `/to-spec` → `/to-tickets` → `/implement`; the path when implementation requires multiple tickets or a richer requirements artifact.
- **map continuation** — a Wayfinder outcome that reports a spec-ready route, an optional one-ticket shortcut, one or more uncharted follow-up maps, or a deliberate stop. Wayfinder does not call `/implement` directly.
- **triage route** — `/triage` classifies an intake record as clarification-needed, bounded implementation, published spec, human-owned, or rejected/already implemented, then points to the matching continuation without mislabeling unfinished planning as a spec.

## Conventions (TDD)

- **feedback-first** — The agent needs a runnable pass/fail check before code, at the smallest provable slice; E2E/acceptance is the final gate, never the first step. Replaces type-first framing (unit tests first, E2E trailing).
- **smallest provable slice** — The thinnest runnable vertical check through real seams that proves a ticket's slice works (one request, one assertion, happy path). Not a full E2E browser test; not a mocked unit test.
- **test list** — Transient external state (`test-list.md`) listing the tests to write, derived from a ticket's acceptance criteria. Drives ordering one test at a time; prevents coding ahead and cheating. Never committed — the skill carries an explicit delete rule: the committed tests are the record, the plan file is deleted when the ticket is done (mirrors the research-dispatch cleanup pattern).
- **test concern** — A coherent contract boundary for executable repository validation: repository/Makefile/CI contracts or skill/workflow contracts.
- **modular repository test suite** — The executable test suite organized by test concern behind the unchanged `make test` entrypoint, with deterministic execution and concern-specific diagnostics.
- **test parity** — Evidence that modularization preserves the existing suite's assertions and failure semantics by inventorying each assertion, mapping it to a concern, and running the complete offline suite.
- **cheating defenses** — Agent anti-patterns: deleting/disabling a red test to pass, "looks done" without a run, coding ahead of the test list, authoring mocks so a test passes trivially.
- **test-first pairing** — Escalation pattern: for larger slices or long runs, dispatch a separate agent to write tests and another to implement to pass them. Not the default; coverage review already provides post-hoc fresh-context scrutiny.

## Shared modules

- **command-runner** — Single source of truth for detecting and invoking the project's command runner (Makefile or justfile). Skills that need to run project targets read from here rather than reimplementing detection.
- **issue-hierarchy** — Shared relationship contract for ticket workflows; forge skills provide the commands, while GitHub uses child issues and GitLab uses task work items under issues.
- **issue-template** — Canonical template for agent-grabbable tickets (`## What to build`, `## Acceptance criteria`, `## Blocked by`). Used by `to-tickets` (creates), `implement` and `triage` (consume).
- **label-taxonomy** — Single source of truth for every label scope, value, and color token. Also carries the usage instruction (how to pass `--color`).
- **color-palette** — Hex values for every color token referenced by the label taxonomy.

## Artifacts

- **language profile** — Per-ecosystem catalog of tools, conventions, and constraints (e.g., Go: golangci-lint, gofumpt via go tool, Makefile). Consumed by bootstrap and CI generation. Not hardcoded commands — declares what to use and constraints; the agent resolves invocation.
- **base profile** — Fallback language profile for languages without a dedicated profile. Carries language-agnostic defaults (generic CI, README); no ecosystem-specific tooling.

## Conventions

- **Makefile/justfile** — Ecosystem-native command runner, single source of truth for tooling. Go uses Makefiles; Rust uses justfiles. Standard targets: `check` (lint, fmt, typecheck), `test` (full suite, vuln scan, review), `lint`, `fmt`.
- **pre-commit hook** — Dumb mechanical gate that runs `make check`. Fast, no agent needed.
- **CI pipeline** — Agent-generated from language profile. Runs `make test`. Not a hardcoded template — the agent renders it fresh, researching latest versions.
- **version pinning rule** — Always research the latest stable version before pinning any dependency (GitHub Actions, SDKs, tools). Training data is stale; primary sources are current.

## Gates

- **quality gate** — Pre-commit: `make check` (hook) + pre-commit agent check. CI: `make test` (full suite). Hard block — failures prevent commit.
- **docs gate** — Pre-commit agent check: does the diff invalidate any existing doc file (README, CONTRIBUTING, CHANGELOG)? Auto-updates before commit. Hard block.
- **universal commit gate** — Any skill that produces a commit goes through the `commit` skill. No single skill owns code changes; the gate owns them.

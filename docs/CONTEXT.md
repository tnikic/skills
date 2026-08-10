# Context

Glossary of domain terms for the agent skills ecosystem.

## Skills

- **bootstrap** — Skill that aligns any repo to the standard project shape (Makefile/justfile, CI, pre-commit hook, README) using a language profile.
- **commit skill** — Universal choke point that gates quality (lint, fmt, typecheck) and docs (freshness check) before any `git commit`. Calls `conventional-commits` for the message.
- **capture** (`/capture`) — User-invoked skill for filing bugs (forensic auto-capture) or ideas (lightweight) into the ticket pipeline. Front door to `triage` → `to-tickets` → `implement`.
- **handoff** — Named invocation point for compacting the current session into a handoff document for a fresh agent. Used at context-limit boundaries.

## Shared modules

- **command-runner** — Single source of truth for detecting and invoking the project's command runner (Makefile or justfile). Skills that need to run project targets read from here rather than reimplementing detection.
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

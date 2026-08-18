# skills

## Introduction

Agent skills for the pi coding agent. The repository packages reusable workflows for bootstrapping projects, capturing work, triaging tickets, implementing changes, and handing work to a human reviewer.

## Quick Start

Clone the skills into the directory your agent scans:

```bash
git clone https://github.com/tnikic/skills.git ~/.agents
```

Skills are discovered automatically. Run `/bootstrap` in a project to align its tooling, or run `/capture` to file a bug or idea.

### Repository setup

Install the forge and local validation tools with [mise](https://mise.jdx.dev/) or another package manager:

| Tool | Used by | Install (mise) |
|------|---------|----------------|
| [gh](https://github.com/cli/cli) | GitHub issue and PR operations | `mise use gh` |
| [glab](https://github.com/glab-cli/glab) | GitLab issue and MR operations | `mise use glab` |
| [gitleaks](https://github.com/gitleaks/gitleaks) | Secret scanning | `mise use gitleaks` |
| [lychee](https://github.com/lycheeverse/lychee) | Offline skill-link validation | `mise use lychee` |
| [vhs](https://github.com/charmbracelet/vhs) | Bootstrap demonstrations | `mise use vhs` |
| [ttyd](https://github.com/tsl0922/ttyd) | Bootstrap terminal recordings | `mise use ttyd` |

Protect the default branch with the repository's forge ruleset or branch protection. Require the `check` and `test` statuses from `.github/workflows/ci.yml`. `implement` also requires an explicit `HUMAN_REVIEWER` before it can hand off a PR.

## How It Works

The skills follow one ticket path:

1. `/capture` records a bug or idea.
2. `/triage` classifies it and `/to-tickets` turns a confirmed spec into agent-ready tickets.
3. `/implement` claims an unblocked ticket, creates a Conventional Branch, and runs the local gates.
4. The agent opens a PR whose body projects the ticket, applies its `impact:*` label, requests review from the explicit `HUMAN_REVIEWER`, and transfers ticket assignment at handoff while leaving the ticket open.
5. CI validates `check` and `test` for the exact current PR head. Required checks determine readiness; optional checks remain informational, and missing protection is a configuration gap.
6. A human reviewer reviews and performs a squash merge. The `Closes #N` relationship closes the ticket only after the merge.

Review feedback stays in the PR. `/review-analysis` separates trusted operator instructions from external comments and delegates approved code changes back to `implement` on the existing branch. Stale or conflicted PRs use `merge-conflict-repair` in an isolated worktree. Neither workflow merges code or changes ticket ownership without its defined handoff.

## Folder Structure

```text
.
├── skills/
│   ├── engineering/
│   ├── productivity/
│   └── shared/
├── docs/
│   ├── CONTEXT.md
│   └── adr/
├── scripts/
│   ├── test.sh
│   └── tests/
├── Makefile
└── .github/
    └── workflows/
        └── ci.yml
```

## How to Test

Run `make check` for fast local validation and `make test` for the complete offline contract suite. The test runner reports repository, skill/workflow, and forge-adapter concerns separately while preserving a non-zero aggregate result.

## Quality gates

The GitHub Actions workflow runs `make check` and `make test` on every pull request. Configure both as required status checks for the authoritative merge gate. A green local commit is not a substitute for CI on the exact current PR head.

## Badges

![License](https://img.shields.io/badge/license-Apache%202.0-blue?style=flat) ![CI](https://github.com/tnikic/skills/actions/workflows/ci.yml/badge.svg)

## Documentation Index

- [Domain context](docs/CONTEXT.md)
- [PR delivery contracts](skills/shared/pr-delivery-contracts.md)
- [PR template](skills/shared/pr-template.md)
- [Issue template](skills/shared/issue-template.md)
- [Label taxonomy](skills/shared/label-taxonomy.md)
- [Command runner contract](skills/shared/command-runner.md)
- [Implement owns PR creation](docs/adr/0009-implement-owns-pr-creation.md)
- [CI is the merge gate](docs/adr/0010-ci-is-the-merge-gate.md)
- [Tickets close at merge](docs/adr/0012-tickets-close-at-merge.md)
- [Pre-PR agent review](docs/adr/0013-pre-pr-agent-review.md)
- [CI results bind to the PR head](docs/adr/0014-ci-results-bind-to-pr-head.md)
- [Dedicated merge-conflict repair](docs/adr/0015-dedicated-merge-conflict-repair.md)
- [Review comment identity boundary](docs/adr/0016-review-comments-have-an-identity-boundary.md)
- [Modular repository test suite](docs/adr/0017-modular-repository-test-suite.md)
- [GitHub forge recipes](skills/engineering/github/SKILL.md)
- [GitLab forge recipes](skills/engineering/gitlab/SKILL.md)

## Agentic Engineering

> This repository is built with **agentic engineering**, a practice where every design decision is made by a human and AI handles the implementation under that direction. The human owns the code, understands every line, and steers the architecture. Nothing lands here without passing through human judgment first.

## Credits

- [Kun Chen](https://github.com/kunchen) - the [AXI](https://github.com/kunchen/axi) principles and repository, which shaped the ergonomic standards for agent-facing CLIs used throughout these skills
- [Matt Pocock](https://github.com/mattpocock) - whose [skills repository](https://github.com/mattpocock/skills) inspired the structure and progressive disclosure patterns used here

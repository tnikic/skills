---
name: review-skill
description: Review an agent skill diff across writing standards, source specification, and behavioral coverage. Use when reviewing skill changes, a skill worktree, or a skill pull request.
---

# Review Skill

Review changes to an agent skill without editing them. Keep the three axes
separate so a polished document cannot hide a missing requirement or an
untested branch.

The review uses [`writing-for-agents`](../../productivity/writing-for-agents/SKILL.md)
as its writing standard and
[`SKILL-MECHANICS.md`](../../productivity/writing-for-agents/SKILL-MECHANICS.md)
for frontmatter and invocation. Use [`codebase-design`](../codebase-design/SKILL.md)
when the change moves behavior across a skill, shared reference, or another
skill.

## 1. Pin the review

Use the fixed point the user supplies: a commit, branch, tag, or merge base.
Capture the diff and commit list once. Confirm the fixed point resolves and the
diff is non-empty before reviewing it. If the user supplied no fixed point, ask
for one. Include uncommitted work only when the user explicitly names the
worktree as the review target.

*Completion: the exact comparison, changed skill paths, and commit range are
recorded.*

## 2. Identify the sources

Find the originating request in this order:

1. An issue or task named by the user or referenced by the commits.
2. A spec or PRD path supplied by the user.
3. A matching document under `docs/`, `specs/`, or `docs/issues/`.
4. No source. Report that the Spec axis has no source rather than inventing
   requirements.

Read the changed skill, every changed or newly reachable pointer, its
`SKILL-MECHANICS.md` branch, relevant `docs/CONTEXT.md` terms, and applicable
ADRs. Identify the repository's `make check` and `make test` targets as the
authoritative deterministic checks.

*Completion: the standards sources, spec availability, reachable documents,
and expected checks are known.*

## 3. Run the three axes in parallel

Use fresh parallel review agents so one judgment does not contaminate another.
Give each agent the fixed diff, source paths, and only the material needed for
its axis.

### Standards

Report every concrete violation or risk against `writing-for-agents` and
`SKILL-MECHANICS.md`:

- frontmatter name, description, and invocation choice
- pointer triggers and reachable links
- steps versus reference and progressive disclosure
- branch coverage and checkable completion criteria
- co-location, pruning, duplicated sources of truth, and negation-led prose
- stale or broken repository conventions

Distinguish a standards violation from a taste preference. Cite the file and
heading or line range for every finding.

### Spec

Report requirements missing or partial, behavior not requested by the source,
and behavior that appears implemented but is wrong. Quote the source for each
finding. If no source exists, report that fact and do not manufacture a Spec
finding.

### Coverage

Report the behavior that the changed skill claims to guide and whether each
branch has an observable completion check or appropriate test evidence. Check
for deterministic repository checks, regression fixtures for known failures,
and fresh-agent or human review where prose quality is subjective. Do not
require model-backed evaluation in `make test`; it is optional evidence, not a
repository gate.

*Completion: all three axes have independent findings, evidence, and explicit
unknowns.*

## 4. Aggregate findings

Present findings first under `## Standards`, `## Spec`, and `## Coverage`.
Within each axis, order findings by severity and include file/line or heading
references, impact, and the smallest correction. Keep the axes separate; do
not let a clean Standards result mask a Spec or Coverage failure.

If no findings exist on an axis, say so explicitly and name the residual risk.
End with counts per axis and the worst finding within each axis. Do not edit the skill, update issue checkboxes, or commit changes during this review.

*Completion: the user has an actionable, axis-separated review and can choose
which findings to fix.*

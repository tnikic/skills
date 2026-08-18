---
name: improve-skill
description: Audit an agent skill for structural and behavioral improvements, then guide a focused change.
disable-model-invocation: true
---

# Improve Skill

Find the highest-leverage improvement to an agent skill, present the options,
and change only the option the user selects. This is the skill-specific version
of an architecture review: the module is the skill document plus its reachable
references, and the interface is the context pointer and process the agent
receives.

Read [`writing-for-agents`](../../productivity/writing-for-agents/SKILL.md) and
[`SKILL-MECHANICS.md`](../../productivity/writing-for-agents/SKILL-MECHANICS.md)
first. Use [`codebase-design`](../codebase-design/SKILL.md) when a proposed
change involves a real seam between a skill, shared reference, or another
skill.

## 1. Scope the review

Review the skill the user names. If none is named, list the skill directories
that appear relevant and ask which one to inspect. Read the full skill, its
reachable pointers, sibling skills that compete for the same invocation, the
domain glossary, and applicable ADRs. Check recent changes when they reveal
the area where maintenance friction is highest.

*Completion: the review target, reachable document set, invocation mode, and
governing decisions are known.*

## 2. Explore the skill

Trace the agent's path through the document and record concrete friction. Check
each category:

- **Pointer:** does the leading wording name what the target contains and every
  branch that should reach it?
- **Hierarchy:** are steps visible, while branch-specific reference is
  progressively disclosed rather than buried or duplicated?
- **Invocation:** does the skill fire autonomously only when it must, or is
  context load being paid for user-only work?
- **Completion:** does every step end with a clear and exhaustive bound that
  resists premature completion?
- **Pruning:** are no-ops, stale caches, negation-led instructions, sprawl,
  and duplicated sources of truth present?
- **Architecture:** would a shared reference or separate skill deepen the
  interface, or merely move the same complexity across a shallow seam?

Apply the deletion test to every proposed split: if removing the proposed
module would not concentrate complexity elsewhere, do not create it.

*Completion: each finding cites a specific file and passage, names the
behavioral cost, and distinguishes a defect from a preference.*

## 3. Present candidates

Present the findings before editing. For each candidate, include:

- **Location** — skill or reference path and heading.
- **Friction** — what makes the agent path unreliable or expensive.
- **Change** — the smallest structural or wording change.
- **Payoff** — expected improvement in context load, cognitive load, locality,
  or agent consistency.
- **Risk** — invocation changes, hidden branches, migration work, or an ADR it
  would reopen.

Recommend one candidate. Do not edit until the user picks a candidate.

*Completion: the user has a bounded choice with a recommendation and enough
evidence to accept, reject, or defer it.*

## 4. Deepen the selected design

Grill the selected candidate through its decision points: which branches are
real, what stays in the main skill, what moves behind a pointer, who invokes
it, and how completion becomes observable. If the candidate introduces a new
concept, use the domain glossary's vocabulary or propose a glossary update.
If it conflicts with an ADR, surface the conflict and ask before reopening it.

For a real seam, compare at least two interfaces using the
`codebase-design` vocabulary: depth, leverage, locality, and the deletion test.
Choose the smallest interface that hides the most implementation without
creating a speculative skill.

*Completion: the selected shape, invocation mode, branch coverage, and source
of truth are agreed before implementation.*

## 5. Implement and verify

Apply the selected change with the smallest correct diff. Preserve unrelated
behavior and update every pointer, shared reference, test, ADR, or README that
the change makes stale. Follow all changed pointers once as a fresh agent
would. Run:

```text
make check
make test
```

Request a fresh review when the change spans multiple skills or changes model
invocation. Fix clear findings and report judgement calls rather than silently
choosing them.

*Completion: the selected improvement is implemented, all reachable material
is consistent, and the applicable checks pass.*

## 6. Report the result

Report the chosen candidate, rejected alternatives, changed paths, invocation
impact, verification outcomes, and any remaining uncertainty. Use the `commit`
skill only when the user explicitly asks for a commit.

*Completion: the user can see why this improvement was chosen and what evidence
supports calling it complete.*

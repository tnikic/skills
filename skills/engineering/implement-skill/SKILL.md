---
name: implement-skill
description: Implement a new agent skill or change an existing one from a clear request, spec, or issue.
disable-model-invocation: true
---

# Implement Skill

Implement a new skill or change an existing skill. Treat the skill document,
its disclosed references, and its invocation mechanics as one behavior surface.
Use [`writing-for-agents`](../../productivity/writing-for-agents/SKILL.md) for
the writing rules and read
[`SKILL-MECHANICS.md`](../../productivity/writing-for-agents/SKILL-MECHANICS.md)
before changing frontmatter or invocation.

## 1. Establish the contract

Use the user's request, spec, or issue as the source of truth. Read the full
target skill, every pointer it reaches for the requested branch, relevant
`docs/CONTEXT.md` terms, and applicable ADRs. Identify the target path,
invocation mode, behavior to add or change, and acceptance criteria. If the
request is too vague to identify those things, ask one focused question before
editing.

*Completion: the target files, intended behavior, invocation choice, and
acceptance criteria are explicit.*

## 2. Shape the document

Map the skill before writing it:

- Put the ordered process in the main file.
- Keep reference beside the process when every branch needs it.
- Disclose branch-specific material behind a pointer whose wording names the
  branch that reaches it.
- Give every step a checkable, exhaustive completion criterion.
- Choose model invocation only when the agent must discover the skill; use
  `disable-model-invocation: true` when the user is the index.

Use one source of truth for each behavior. Prefer a smaller skill with positive
instructions and leading words over repeated prohibitions or explanatory
prose. Split files only when the invocation or sequence boundary earns the
extra cognitive load.

*Completion: the file layout, information hierarchy, branches, and invocation
mechanics have a reason that can be stated in one paragraph.*

## 3. Implement the change

Edit the smallest correct set of files. Keep the skill directory name and
frontmatter `name` aligned. Preserve unrelated content. Keep relative links
valid, co-locate each concept's definition and rules, and make the main steps
visible in execution order. Update shared references, tests, ADRs, or the
README only when the changed behavior makes them stale.

When the skill changes an existing workflow, preserve its existing guarantees
unless the request explicitly changes them. Do not add a second skill or
duplicate a rule when an existing skill or shared reference owns the behavior.

Before declaring the implementation complete, read every changed document as
an agent would, following each new or changed pointer and checking every
branch's completion criterion. Inspect the diff for stale wording, duplicated
rules, broken relative links, and frontmatter that does not match the chosen
invocation.

*Completion: every requested behavior is represented once, every changed
pointer reaches the right material, every changed branch was inspected, and
unrelated content is preserved.*

## 4. Establish green before review

Run the project's `check` target and then its `test` target through the shared
[`command-runner`](../../shared/command-runner.md). Both must pass before any
review starts. If either target fails, repair the implementation and repeat
this gate; review only a green worktree. If no command runner is configured,
relay the command-runner message, record the limitation, and stop before
review rather than claiming a green worktree.

*Completion: the implementation passes both standard targets in sequence, and
the worktree is green before review begins; or, when no runner is configured,
the workflow stops with that unresolved limitation recorded and no review
claimed.*

## 5. Review and repair

A substantial change alters a skill's process, branch behavior,
frontmatter/invocation, or a reachable shared reference. A wording-only or
test-only correction is minor when those remain unchanged. For a substantial
change, invoke `/review-skill` once against the fixed point after the green
gate. This is the normal three-axis checkpoint: Standards, Spec, and Coverage
run in parallel in a fresh review context. Fix clear findings directly;
surface judgement calls to the user.

After a repair, classify its impact before verifying it. Use targeted checks
for wording-only or test-only corrections, and do not repeat the full review
for those corrections. Repeat the full three-axis review only when a repair
materially changes behavior, scope, or invocation mechanics. For that material
repair, pass the green gate again before the rerun. A justified rerun uses the
same fixed point and happens after the repaired worktree is green.

*Completion: a substantial change has one normal review on the green
implementation, a minor correction has targeted verification, every clear
finding was repaired or a judgement call was surfaced, and any review rerun
was justified by a material change.*

## 6. Final verification

After all review repairs and any justified review rerun, run the project's
`check` target and then its `test` target through the shared command runner.
These final full checks are mandatory even when targeted checks passed. They
form a freshness boundary for the post-review worktree; `/commit` retains its
independent staged-diff quality gate and may repeat its own checks.

*Completion: the final standard targets pass in sequence after every repair,
and the independent commit gate remains available.*

## 7. Report the result

Report the changed skill paths, the invocation decision, the behavior added or
changed, verification commands and outcomes, and any unresolved limitation.
Use the `commit` skill if the user explicitly asks for a commit; otherwise
leave committing to the user.

*Completion: the user can distinguish shipped behavior, verified behavior, and
remaining uncertainty from the report.*

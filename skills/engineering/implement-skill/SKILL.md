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

*Completion: every requested behavior is represented once, every changed
pointer reaches the right material, and unrelated content is preserved.*

## 4. Verify

Read every changed document as an agent would, following each new or changed
pointer and checking every branch's completion criterion. Inspect the diff for
stale wording, duplicated rules, broken relative links, and frontmatter that
does not match the chosen invocation. Run the project's `check` and `test`
targets through the shared
[`command-runner`](../../shared/command-runner.md). It detects Make or Just and
reports when no runner is configured.

For a substantial change, run `/review-skill` against the fixed point before
calling it complete. Fix clear findings; surface judgement calls to the user.

*Completion: all reachable references were inspected, the diff is clean, and
the applicable repository checks pass.*

## 5. Report the result

Report the changed skill paths, the invocation decision, the behavior added or
changed, verification commands and outcomes, and any unresolved limitation.
Use the `commit` skill if the user explicitly asks for a commit; otherwise
leave committing to the user.

*Completion: the user can distinguish shipped behavior, verified behavior, and
remaining uncertainty from the report.*

---
name: pr
description: "Prepare a safe implementation branch and hand it through the implementation and commit workflows for PR delivery."
disable-model-invocation: true
---

# PR Workflow

Prepare a non-default implementation branch, then hand the requested work to
`/implement` and `/commit` in that order. This is an additional route for
reviewable delivery; direct `/implement` remains available for ordinary work.

Read the shared [`continuation`](../../shared/continuation.md) contract when
returning the workflow boundary. Keep the exact continuation in the live
interaction rather than in an issue record.

## 1. Establish the delivery target

Use the issue, spec, or settled implementation landscape supplied by the user.
Read its full source and identify the implementation ticket or ordered ticket
set before changing the repository.

Identify the repository default branch from the repository's authoritative
metadata, then inspect the current branch. If the current branch is the
default branch, stop before implementation and give actionable guidance to
create or switch to a non-default implementation branch before invoking `/pr`
again. Do not publish changes from the default branch.

*Completion: the source work is identified, the default branch is recorded,
and execution is either stopped safely on the default branch or continues from
a verified non-default branch.*

## 2. Prepare the implementation branch

Select the requested implementation branch when it already exists. If a new
branch is needed, create it from the current non-default starting point and
switch to it. Verify the current branch is non-default immediately before the
implementation handoff. Preserve a dirty worktree and stop with guidance if a
branch switch would risk unrelated changes.

*Completion: one non-default implementation branch is selected, the worktree
is safe to use, and no implementation has started before this branch check.*

## 3. Delegate implementation

Invoke `/implement` for the identified work in PR-workflow handoff mode.
`/implement` owns issue reading, implementation, validation, review and repair,
and acceptance-criteria handling. In this mode it returns after that work is
complete and does not enter its ordinary commit, issue-closure, or parent-check
route.

If implementation does not complete successfully, stop and preserve the
branch for retry. Do not invoke `/commit` after a failed implementation.

*Completion: `/implement` reports completed implementation and validation on
the selected non-default branch, or the workflow stops with the branch and
failure available for retry.*

## 4. Delegate commit and push

After a successful implementation handoff, invoke `/commit`. The commit skill
owns staging, safety, quality, documentation, message approval, commit
creation, and pushing. Do not run commit or push commands here, and do not
duplicate `/implement`'s implementation or acceptance work.

If `/commit` fails, report the exact gate or push failure and leave the
implementation branch and issue open for retry. Do not claim PR readiness.

*Completion: `/commit` reports the selected non-default branch's commit as
pushed, or the failure is reported without claiming publication.*

## 5. Return the PR boundary

After the commit gate succeeds, report the branch and commit as ready for the
provider-specific PR publication workflow. Keep the issue open: this boundary
does not close issues or publish forge-specific records. Return the complete
continuation set with the current state, ready-now actions, later actions,
dependencies, and deliberate stop fields.

*Completion: the pushed implementation branch, commit, and next PR-publication
boundary are reported, with no premature issue closure or forge-specific
operation claimed.*

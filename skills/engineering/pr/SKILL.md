---
name: pr
description: "Advance one implementation ticket through a safe branch, commit gate, and forge review record."
disable-model-invocation: true
---

# PR Workflow

Advance one implementation ticket from a spec through exactly one non-default
branch and one review record, then hand the work to `/implement`, `/commit`,
and the matching forge publication operation in that order. Each implementation
ticket gets its own branch and review record. A spec's tickets advance
sequentially through one linear stack, while separate specs have independent
roots. This is an additional route for reviewable delivery; direct `/implement`
remains available for ordinary work.

Read the shared [`continuation`](../../shared/continuation.md) contract when
returning the workflow boundary. Keep the exact continuation in the live
interaction rather than in an issue record.

Read the provider-neutral [`forge-pr-delivery-contract`](../../shared/forge-pr-delivery-contract.md)
and [`pr-template`](../../shared/pr-template.md) when handing a pushed ticket
to a forge. Render the ticket body from the template, then ask the matching
forge skill to perform the named operation and consume its normalized record or
retryable failure. Keep provider commands, response fields, and native stack
mechanics in that forge skill.

## 1. Establish the delivery target and stack plan

Use the issue, spec, or settled implementation landscape supplied by the user.
Read the full source, all comments, and native child ticket records. Identify
the current spec, its implementation tickets, their declared order and
dependency edges, and the ticket to advance. When the input is a spec, select
one next ticket; when it is a ticket, use that ticket and still validate its
spec landscape.

Select the next ready ticket with this stable key, in order: declared spec or
dependency order, tracker priority, ticket creation time, then issue number as
the final deterministic tie-breaker. A ticket is ready when it has no
spec-local predecessor or its predecessor is merged or implementation-ready,
and every dependency outside the current spec is closed. An
implementation-ready predecessor is sufficient to start downstream
implementation; it does not need to be merged first.

Validate that the current spec is one linear chain: each ticket has at most one
spec-local predecessor and the ordered tickets do not fork, fan in, or cycle.
If the graph is non-linear, stop before creating a branch or publishing a
review record. Report the offending tickets and edges, explain that the forge
cannot infer stack ancestry, and give the actionable fix: linearize the
dependencies or split the work into separate specs. Keep external open
dependencies as blockers and report the blocking issue or task. Never use a
ticket from another spec as a parent branch or blocker shortcut.

Identify the repository default branch from the repository's authoritative
metadata, then inspect the current branch. If the current branch is the
default branch, stop before implementation and give actionable guidance to
create or switch to a non-default implementation branch before invoking `/pr`
again. Do not publish changes from the default branch.

*Completion: the full spec landscape is read, one deterministic ready ticket is
selected or a blocker/non-linear stop is reported, the linearity and external
dependencies are verified, the default branch is recorded, and execution is
either stopped before repository changes or continues from a verified
non-default branch.*

## 2. Prepare the implementation branch and topology

Select the requested implementation branch when it already exists. If a new
branch is needed, create it from the current non-default starting point and
switch to it. Verify the current branch is non-default immediately before the
implementation handoff. Preserve a dirty worktree and stop with guidance if a
branch switch would risk unrelated changes.

Use one deterministic source branch for the selected ticket, such as
`feat/<ticket>-<slug>`. The first ticket in a spec targets the default branch;
each later ticket targets exactly its predecessor's source branch. Start a
later ticket from that implementation-ready predecessor branch, so merge is
not required before downstream implementation. A branch belongs to one ticket
and one spec; never share branch state across separate specs. Keep this native
source/target topology in the selected forge skill rather than simulating
stack operations here.

Carry this selected branch unchanged through implementation, commit, push, and
publication; the ticket has one implementation branch.

*Completion: one non-default implementation branch and its predecessor or
default target are selected, the worktree is safe to use, and no implementation
has started before this branch and topology check.*

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

## 5. Publish one review record

Choose the forge matching the repository and follow exactly one provider branch
below. Read the provider-neutral
[`forge-pr-delivery-contract`](../../shared/forge-pr-delivery-contract.md) and
[`pr-template`](../../shared/pr-template.md) before handing off publication.

Render one ticket-focused body from the shared template, using the ticket title
as the publication title. Fill `Change scope`,
`Notable decisions`, `Validation`, and `Acceptance results` from the ticket and
the completed `/implement` result; include every ticket criterion in
`Acceptance results`. Fill `Spec context` when a parent spec is relevant,
`Stack position` as the ticket's position and total followed by
`-> <target branch>`, and `Dependency context` with the resolved prerequisites
or the actual blocker. In `Related records`, use
`Related: #N` or `Refs: #N` for the open ticket. The intermediate publication
reference is non-closing, so this body does not use `Closes #N`.

### GitHub pull request

Use the GitHub skill for the selected provider branch and its normalized
publication result.

### GitLab merge request

Use the GitLab skill for the selected provider branch and its normalized
publication result.

Ask the selected forge skill to run the provider-neutral `find` operation by
source branch first. When it returns `record: null`, ask it to run one `create`
operation with the ticket body, source branch, and the selected target branch.
When it finds an existing record, reuse that record instead of creating
another. The forge skill owns native synchronization, rebasing, branch updates,
and retargeting; the workflow only reconciles the normalized result against its
planned topology.
Consume the resulting normalized publication record; the workflow does not
derive provider commands or response fields. Reconcile its `record_id`, `url`,
`title`, `body`, `source_branch`, `target_branch`, `head_sha`, and `state` against
the ticket body, selected source branch, selected target branch, and pushed
commit before reporting readiness. A mismatch is a publication failure and
remains retryable with the branch and issue preserved.

If the forge returns a `publication_failure`, stop at this boundary. Preserve
the pushed branch and open issue, report the contract's failure class, message,
and recovery action, and retain `retryable: true`,
`publication_exists: false|unknown`, `preserved_branch: true`, and
`preserved_issue: true`. Do not claim that a pull request or merge request
exists or that the ticket is implementation-ready. A retry finds by source
branch before any create operation.

*Completion: exactly one open pull-request or merge-request record from the
selected forge is represented by one normalized publication result, or a
retryable failure is reported with the branch and issue preserved and no
publication claimed.*

## 6. Return the implementation-ready boundary and merge order

Report `implementation-ready` only when `/implement` completed validation,
`/commit` reports one pushed commit, and the selected forge result is one
normalized record whose state is `open`. Keep the ticket open at this
boundary. The open issue plus the open review record is implementation-ready;
`merged` is a separate review-record state, and `closed` is a later issue
lifecycle state after the change reaches the default branch. Do not close the
ticket or alter the parent spec from this workflow.

Return the complete continuation set using the shared
[`continuation`](../../shared/continuation.md) contract, with the current state,
ready-now actions, later actions, dependencies, and deliberate stop fields.

Report the spec's required human merge order from the lowest branch to the
highest branch. Human review and merge remain outside this workflow: do not
approve, merge, or close records here. After a predecessor is merged, the
matching forge skill reconciles the native stack and any target updates; the
workflow does not invent ancestry or mark downstream tickets merged.

When the current ticket is implementation-ready and the next linear ticket has
no open external blocker, expose that downstream implementation as a later or
ready-now continuation with the predecessor branch as its target. Separate
specs may expose independent roots, but one spec's merge order never delays
implementation in another spec.

*Completion: the issue remains open, the implementation-ready state is
reported only for an open normalized pull request or merge request, and merged
or closed states remain distinguishable in the continuation set; the required
human merge order and any independent downstream continuation are reported.*

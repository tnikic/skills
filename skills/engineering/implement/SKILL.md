---
name: implement
description: "Implement work from a spec or issue. Picks the next unblocked agent-ready issue when none is given."
disable-model-invocation: true
---

Implement the work in the given issue, or pick the next unblocked one.

Forge operations (issue lifecycle, claims, hierarchy queries, follow-ups) run through the [`github`](../github/SKILL.md) or [`gitlab`](../gitlab/SKILL.md) skill matching the repo's forge.

For PR-based delivery, use the shared [PR template](../../shared/pr-template.md)
and [delivery contracts](../../shared/pr-delivery-contracts.md) for branch
names, PR titles, lifecycle, and review impact. Forge-specific command syntax
remains in the forge skill.

## 1. Pick the work

If the user passed a spec or issue, use it directly. Read its full body. If it's empty or a vague one-liner with no clear spec, warn and ask whether to proceed anyway. If the user confirms, skip to step 2. If the user says no, fall through to the query path below.

Otherwise, query open issues:

1. Automatic selection includes only open issues labeled `triage:for-agent`.
2. Start with unassigned and unblocked agent-ready issues, sorted by priority then age. An issue is unblocked only when every issue in its `blockedBy` relationship is closed. Inspect each blocker state; closed links do not block selection, while any open blocker excludes the candidate.
3. If none, use the assigned-to-@me fallback, still requiring `triage:for-agent` and no open blockers.
4. Exclude `triage:pending`, `triage:unanswered`, unlabeled, `triage:for-human`, and `triage:wontfix` issues.
5. Query open `triage:pending` issues separately and report them in a `requires triage` section.

Read the full body of each candidate. Skip any whose body is empty or a vague one-liner with no clear spec.
If no eligible issue remains, report that no implementation-ready issue exists and stop without claiming one.

Present the shortlist with a recommendation for the top candidate, including a one-line summary from the body:

> Three unblocked issues are open. I recommend #42 — Fix login timeout: adds a lockout after 3 failed attempts.
> - #42 Fix login timeout: adds a lockout after 3 failed attempts (priority: high)
> - #57 Add rate limiting: token-bucket rate limiter on API routes (priority: medium)
>
> Work on #42?

For assigned-to-you issues, preface with:

> No unassigned issues. These are assigned to you — already in progress, or should I take one?

Assign the issue to @me to claim it.

*Completion: an issue with a clear spec is confirmed and assigned.*

## 2. Implement and prepare the change

Create or adopt the Conventional Branch before editing tracked files:

- Read the originating spec delivery mode from the shared [delivery contracts](../../shared/pr-delivery-contracts.md) before selecting the branch. Per-ticket delivery is the default; use the combined form only when the spec explicitly opts into `delivery: combined`, or the stacked form when it explicitly opts into `delivery: stacked`.
- Derive `<type>` from the ticket's dominant commit type, using `chore` when no type is declared. In combined mode, derive `<type>` once from the spec's dominant commit type so every ticket uses the same branch. Use the spec slug as the lowercase kebab-case description.
- For the default per-ticket mode, if the current branch already matches `<type>/<ticket-number>-<spec-slug>`, adopt it. Otherwise create or switch to that branch before continuing.
- For `delivery: combined`, use one `<type>/<spec-slug>` branch for every ticket in the spec.
- Adopt the existing combined branch when present and keep its PR open.
- Deliver later tickets with incremental pushes instead of creating new ticket branches or PRs.
- For `delivery: stacked`, retain the per-ticket branch name.
- The first ticket in the spec's declared order uses the repository default branch as `base`.
- Each later ticket uses the preceding ticket's branch as the previous stack branch. Retarget the PR through the forge skill when that predecessor merges to the default branch; do not implement stack ordering, merge, or rebase behavior in this workflow.

The default path is one per-ticket branch and one PR for this ticket. Combined and stacked paths are opt-in and leave the default path unchanged.

Use TDD at pre-agreed seams. Run the project's standard targets for static analysis alongside single test files as you go — see [`command-runner.md`](../../shared/command-runner.md) for detection and target names. Run the local gates in this order:

1. Run the project `check` target.
2. Invoke `/code-review` with the scope `Standards and Spec` against the complete working-tree diff from the branch merge-base and the originating issue or spec. Coverage remains owned by `improve-codebase-architecture` and is not part of this workflow.
3. Fix clear-cut review findings. Pause for human input on any judgment-dependent finding.
4. Run the project `check` target again after corrections.
5. Run the project `test` target once at the end of the implementation loop.
6. Invoke `/commit` as the universal commit-quality and documentation gate. Do not derive `Closes` or `Refs` metadata from branch names or add forge-specific issue relationships to the commit message.

### Pre-PR Implementation Loop Policy

This policy covers only the `implement` pre-PR loop. The post-PR `review-analysis` batching remains out of scope; that skill owns the separate process for handling comments on an open PR.

The sequence above is one bounded pass:

1. Run the initial `check`.
2. Run one Standards/Spec review.
3. The correction step must batch all clear-cut findings from one review pass and apply that correction batch without running an intermediate gate.
4. Run one corrective `check` for the batch.
5. Run the final `test`.
6. Run the commit gate.

The review pass classifies findings before edits are made:

- Mechanical corrections stay in the current loop when they are ticket-scoped fixes such as formatting, naming, duplication, or linter findings. They are applied together and do not trigger a full Standards/Spec review rerun.
- Semantic or user-directed changes start a new Standards/Spec review before the implementation continues. They are not silently folded into the current correction batch.
- Judgment-dependent findings stop the loop and wait for human direction; no later gate can make an unresolved decision safe.

When a gate fails, the loop re-enters at the narrowest applicable gate rather than restarting unchanged checks:

- A `check` failure is corrected and rechecked. The initial review remains valid unless the correction is semantic.
- A failed corrective `check` is corrected and rechecked; it does not restart the review when the correction is mechanical.
- A `test` failure is corrected and the test is rerun. A behavioral correction starts a new Standards/Spec review, followed by the required checks and final test.
- A commit-gate failure is corrected and the commit gate is rerun. Earlier successful gates remain valid unless the correction changes their inputs.

The rule is that unchanged checks remain valid when none of their tracked inputs changed after they passed and no new user intent or branch-base change invalidated their results. Any correction invalidates only the gates that consume the changed inputs. This policy avoids redundant reruns but does not weaken required quality, documentation, security, or final test gates: every required gate still runs successfully before handoff, and each failed gate is rerun at its applicable entry point.

If any local gate fails, stop without committing, pushing, or closing the ticket; leave the ticket open and assigned.

A judgment-dependent finding has the same outcome until the human provides a decision.

*Completion: every spec requirement is implemented, every local gate passes in order, and one universal-gate commit is created.*

## 3. Review, fix, and check acceptance criteria

The pre-PR review follows the scope and diff boundary in step 2. Fix clear-cut findings directly — naming, duplication, and any linter or formatter violations. For architectural judgment calls — Feature Envy, Shotgun Surgery, Divergent Change — pause and present them for approval with a recommendation.

If the review comes back clean, report it briefly.

### 3a. Check acceptance criteria

Read the issue body and all comments for unchecked boxes (`- [ ]` or `* [ ]`). For each, judge whether the implementation satisfied it. Presume satisfied unless you know a criterion was skipped, blocked, or impossible.

Treat the issue body as the canonical source for body checkboxes. Update the original issue body in place via the forge skill's issue-edit recipe, preserving all unrelated text and replacing only satisfied `- [ ]` or `* [ ]` markers with checked markers. Record each criterion only in its source container.

For checkboxes that exist only in comments, edit the original comment in place via the forge skill's comment-edit recipe, preserving all unrelated text and replacing only satisfied markers. This keeps comment-only criteria in their source comment while body criteria remain in the issue body. Leave unsatisfied criteria unchecked.

If any criterion is unsatisfied, report which ones and why to the user. Offer to create follow-up tickets via the forge skill's issue-create recipe, following the template in [`issue-template.md`](../../shared/issue-template.md). Apply the same labels as the current issue. Parent each follow-up to the current issue's parent (if it has one); otherwise create it standalone. Add a comment on the current issue linking each follow-up.

If neither the issue body nor comments contain any checkboxes, skip this step.

*Completion: every satisfied body criterion is checked in the issue body, every satisfied comment-only criterion is checked in its source comment, and unsatisfied criteria are reported to the user with follow-up tickets offered.*

## 4. Open the reviewable PR

After `/commit` succeeds, push the Conventional Branch with `git push -u origin HEAD`.
If the push fails, report the failure and leave the ticket open and assigned.

Render the PR body from the shared [PR template](../../shared/pr-template.md):

1. State the ticket's user-visible purpose in `What this does`.
2. List the resulting implementation changes in `Changes`.
3. Mirror every ticket acceptance criterion without changing its wording.
4. Add `Closes #N` as the final relationship footer. In combined mode, add one
   footer for each ticket carried by the shared PR.

Resolve the ticket's declared review impact, defaulting to `normal` when it is
omitted. Apply the declared `impact` value, defaulting to `impact:normal`, as
the PR label. Impact is review triage only and never gates the handoff.

Require `HUMAN_REVIEWER` as explicit workflow input. Read it from the invocation context or ask the user. If it is absent, keep the ticket open and
assigned until the user provides it. Never substitute the agent identity for the human reviewer.

Create or update one PR through the matching forge skill's `find_pr`, `create_pr`,
or `update_pr` recipe.
Use the current branch as `head`, the repository default branch as `base` for
per-ticket and combined delivery, or the previous stack branch as `base` for
stacked delivery. Use the provisional `[<spec-slug> <n>/<N>] <summary>` title form
and the rendered PR body. In combined mode, call `find_pr` by the shared head
branch before creating; if one open PR exists, read its body and all tickets in
the spec's declared order, render the cumulative changes, criteria, and
`Closes #N` footers, then use `update_pr` and push incrementally instead of
opening another PR. More than one match is an error. In stacked mode, use
`retarget_pr` when the predecessor merges to the default branch. Each recipe
must return the PR number, URL, base and head branches, current head SHA, and
open state.

Pass the PR number and current head SHA to the exact-head readiness workflow.
It discovers required checks through `discover_required_checks`, waits within
its bounded window, and maps `status_for_head` success for that exact SHA to
ready for review. Stop only after that workflow reports the PR ready for
review. A non-success outcome leaves the PR open and not ready, keeps the
ticket assigned, and is reported with its evidence.

Assign `HUMAN_REVIEWER` and request review through the forge skill's
`assign_reviewer` recipe. Use the forge issue-edit recipe to transfer the
ticket assignment to that reviewer while keeping the ticket open. Report the
PR URL and stop at the ready-for-review handoff; the human owns approval and
squash merge.

Keep forge-specific issue-closing metadata out of the commit. The ticket
closes only when the PR merges through its `Closes #N` relationship. The exact
PR-head readiness wait is a later workflow stage, so a newly opened PR remains
open while that stage evaluates its required checks.

*Completion: one commit is pushed, one PR is open with the projected ticket,
impact, reviewer request, and open assigned ticket state.*

## 5. Post-merge parent check

After the human merges the PR and the linked ticket is closed, if this
workflow is invoked for post-merge cleanup and the closed issue has a
`parent`, list the parent's sub-issues. When all are closed, tell the user:
"All sub-issues of #<parent> are closed. Close it as well?" The user confirms
or declines. If confirmed and that parent itself has a parent, recurse.

*Completion: parent closure offered where applicable; user decision handled.*

When a parent `kind:spec` is closed, remind the user: "The spec is closed. Consider running `/update-docs` to bring the README up to date with everything that shipped."

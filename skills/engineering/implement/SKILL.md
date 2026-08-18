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
2. Start with unassigned and unblocked agent-ready issues, sorted by priority then age.
3. If none, use the assigned-to-@me fallback, still requiring `triage:for-agent` and no blockers.
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

- Select the per-ticket or explicitly combined form from the shared [delivery contracts](../../shared/pr-delivery-contracts.md), then create or adopt that branch.
- Derive `<type>` from the ticket's dominant commit type, using `chore` when no type is declared. Use the spec slug as the lowercase kebab-case description.
- If the current branch already matches the documented name, adopt it. Otherwise create or switch to the documented branch before continuing.

Use TDD at pre-agreed seams. Run the project's standard targets for static analysis alongside single test files as you go — see [`command-runner.md`](../../shared/command-runner.md) for detection and target names. Run the local gates in this order:

1. Run the project `check` target.
2. Invoke `/code-review` with the scope `Standards and Spec` against the complete working-tree diff from the branch merge-base and the originating issue or spec. Coverage remains owned by `improve-codebase-architecture` and is not part of this workflow.
3. Fix clear-cut review findings. Pause for human input on any judgment-dependent finding.
4. Run the project `check` target again after corrections.
5. Run the project `test` target once at the end of the implementation loop.
6. Invoke `/commit` as the universal commit-quality and documentation gate. Do not derive `Closes` or `Refs` metadata from branch names or add forge-specific issue relationships to the commit message.

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

## 4. Deliver the gated change

After `/commit` succeeds, the universal-gate commit is ready to deliver. Keep
forge-specific issue-closing metadata out of the commit; the PR body carries
`Closes #N` instead. Amend an earlier commit if one was already made.

Push: `git push -u origin HEAD`. If the push fails, report the failure and stop — do not close the issue.

Verify closure: poll the issue state every 3 seconds, up to 3 attempts. If the issue is now closed, stop. If still open after 3 attempts, close it manually via the forge skill's issue-close recipe.

*Completion: one commit pushed, issue closed.*

## 5. Parent check

If the closed issue has a `parent`, list the parent's sub-issues. When all are closed, tell the user: "All sub-issues of #<parent> are closed. Close it as well?" The user confirms or declines. If confirmed and that parent itself has a parent, recurse.

*Completion: parent closure offered where applicable; user decision handled.*

When a parent `kind:spec` is closed, remind the user: "The spec is closed. Consider running `/update-docs` to bring the README up to date with everything that shipped."

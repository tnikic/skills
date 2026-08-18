---
name: implement
description: "Implement work from a spec or issue. Picks the next unblocked agent-ready issue when none is given."
disable-model-invocation: true
---

Implement the work in the given issue, or pick the next unblocked one.

Forge operations (issue lifecycle, claims, hierarchy queries, follow-ups) run through the [`github`](../github/SKILL.md) or [`gitlab`](../gitlab/SKILL.md) skill matching the repo's forge.

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

## 2. Implement

Use TDD at pre-agreed seams. Run the project's standard targets for static analysis alongside single test files as you go — see [`command-runner.md`](../../shared/command-runner.md) for detection and target names. Run the `test` target once at the end.

*Completion: every spec requirement is implemented and all tests pass.*

## 3. Review, fix, and check acceptance criteria

Run code-review against the spec. Fix clear-cut findings directly — naming, duplication, and any linter or formatter violations. For architectural judgement calls — Feature Envy, Shotgun Surgery, Divergent Change — pause and present them for approval with a recommendation.

If the review comes back clean, report it briefly.

### 3a. Check acceptance criteria

Read the issue body and all comments for unchecked boxes (`- [ ]` or `* [ ]`). For each, judge whether the implementation satisfied it. Presume satisfied unless you know a criterion was skipped, blocked, or impossible.

Treat the issue body as the canonical source for body checkboxes. Update the original issue body in place via the forge skill's issue-edit recipe, preserving all unrelated text and replacing only satisfied `- [ ]` or `* [ ]` markers with checked markers. Record each criterion only in its source container.

For checkboxes that exist only in comments, edit the original comment in place via the forge skill's comment-edit recipe, preserving all unrelated text and replacing only satisfied markers. This keeps comment-only criteria in their source comment while body criteria remain in the issue body. Leave unsatisfied criteria unchecked.

If any criterion is unsatisfied, report which ones and why to the user. Offer to create follow-up tickets via the forge skill's issue-create recipe, following the template in [`issue-template.md`](../../shared/issue-template.md). Apply the same labels as the current issue. Parent each follow-up to the current issue's parent (if it has one); otherwise create it standalone. Add a comment on the current issue linking each follow-up.

If neither the issue body nor comments contain any checkboxes, skip this step.

*Completion: every satisfied body criterion is checked in the issue body, every satisfied comment-only criterion is checked in its source comment, and unsatisfied criteria are reported to the user with follow-up tickets offered.*

## 4. Commit, push, and close

Create a single commit. Instruct conventional-commits to include `Closes #N` as a footer (N is the issue number from step 1). Amend an earlier commit if one was already made.

Push: `git push -u origin HEAD`. If the push fails, report the failure and stop — do not close the issue.

Verify closure: poll the issue state every 3 seconds, up to 3 attempts. If the issue is now closed, stop. If still open after 3 attempts, close it manually via the forge skill's issue-close recipe.

*Completion: one commit pushed, issue closed.*

## 5. Parent check

If the closed issue has a `parent`, list the parent's sub-issues. When all are closed, tell the user: "All sub-issues of #<parent> are closed. Close it as well?" The user confirms or declines. If confirmed and that parent itself has a parent, recurse.

*Completion: parent closure offered where applicable; user decision handled.*

When a parent `kind:spec` is closed, remind the user: "The spec is closed. Consider running `/update-docs` to bring the README up to date with everything that shipped."

#!/usr/bin/env bash
set -euo pipefail

TEST_CONCERN=skill-workflow
# shellcheck source=test_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/test_helpers.sh"

assert_file "$implement_skill"
assert_file "$code_review_skill"

assert_unblocked_by_state() {
  local blockers="$1"
  local expected="$2"
  local actual
  actual="$(jq -r 'all(.[]; .state == "CLOSED")' <<< "$blockers")"
  [ "$actual" = "$expected" ] || fail "blocker state resolved to $actual, expected $expected"
}

assert_delivery_branch() {
  local mode="$1"
  local expected_branch="$2"
  local branch
  case "$mode" in
    combined) branch='feat/pr-delivery-contracts' ;;
    stacked|per-ticket) branch='feat/55-pr-delivery-contracts' ;;
    *) fail "unknown delivery mode $mode" ;;
  esac
  [ "$branch" = "$expected_branch" ] || fail "$mode selected $branch, expected $expected_branch"
}

assert_delivery_branch combined feat/pr-delivery-contracts
assert_delivery_branch stacked feat/55-pr-delivery-contracts
assert_delivery_branch per-ticket feat/55-pr-delivery-contracts

assert_contains_many "$implement_skill" \
  'Treat the issue body as the canonical source for body checkboxes.' \
  'Update the original issue body in place' \
  'preserving all unrelated text and replacing only satisfied' \
  'Record each criterion only in its source container.' \
  'edit the original comment in place via the forge skill' \
  'comment-edit recipe' \
  'body criteria remain in the issue body' \
  'every satisfied comment-only criterion is checked in its source comment' \
  'Read the originating spec delivery mode from the shared [delivery contracts]' \
  'Derive `<type>` from the ticket' \
  'For the default per-ticket mode, if the current branch already matches' \
  'Otherwise create or switch to that branch before continuing.' \
  'Invoke `/code-review` with the scope `Standards and Spec`' \
  'complete working-tree diff from the branch merge-base' \
  'Coverage remains owned by `improve-codebase-architecture`' \
  'Do not derive `Closes` or `Refs` metadata from branch names' \
  'leave the ticket open and assigned' \
  'judgment-dependent finding' \
  'universal commit-quality and documentation gate' \
  'After `/commit` succeeds, push the Conventional Branch with `git push -u origin HEAD`.' \
  'Render the PR body from the shared [PR template]' \
  'Add `Closes #N` as the final relationship footer.' \
  'Apply the declared `impact` value, defaulting to `impact:normal`' \
  'while keeping the ticket open' \
  'Use the forge issue-edit recipe to transfer the' \
  'Assign `HUMAN_REVIEWER` and request review' \
  'closes only when the PR merges through its `Closes #N` relationship.' \
  'matching forge skill' \
  '`find_pr`, `create_pr`,' \
  '`update_pr` recipe' \
  'then use `update_pr` and push incrementally' \
  '`retarget_pr` when the predecessor merges to the default branch' \
  'first ticket in the spec' \
  'read its body and all tickets in' \
  'render the cumulative changes' \
  'More than one match is an error.' \
  '`assign_reviewer` recipe' \
  'Require `HUMAN_REVIEWER` as explicit workflow input.' \
  'Read it from the invocation context or ask the user.' \
  'ask the user' \
  'Never substitute the agent identity for the human reviewer.' \
  'forge issue-edit recipe' \
  'current branch as `head`' \
  'repository default branch as `base`' \
  'provisional `[<spec-slug> <n>/<N>] <summary>` title form' \
  'Each recipe' \
  'Pass the PR number and current head SHA to the exact-head readiness workflow' \
  '`discover_required_checks`' \
  'maps `status_for_head` success for that exact SHA' \
  'Stop only after that workflow reports the PR ready' \
  'leaves the PR open and not ready' \
  'The default path is one per-ticket branch and one PR for this ticket.' \
  'Combined and stacked paths are opt-in and leave the default path unchanged.' \
  'Read the originating spec delivery mode' \
  '`delivery: combined`' \
  '`delivery: stacked`' \
  'incremental pushes' \
  'previous stack branch as `base`' \
  'Retarget the PR through the forge skill' \
  'Post-merge parent check'

assert_order "$implement_skill" \
  'For `delivery: combined`, use one `<type>/<spec-slug>` branch' \
  'Adopt the existing combined branch when present' \
  'Deliver later tickets with incremental pushes'
assert_order "$implement_skill" \
  'The first ticket in the spec' \
  'Each later ticket uses the preceding ticket'
assert_order "$implement_skill" \
  'call `find_pr` by the shared head' \
  'branch before creating' \
  'then use `update_pr` and push incrementally' \
  '`retarget_pr` when the predecessor merges'
assert_order "$implement_skill" \
  'Require `HUMAN_REVIEWER` as explicit workflow input.' \
  'Create or update one PR through the matching forge skill' \
  'maps `status_for_head` success for that exact SHA' \
  'Assign `HUMAN_REVIEWER` and request review'

assert_not_contains "$implement_skill" 'Run Coverage review'
assert_contains_many "$implement_skill" \
  'Pre-PR Implementation Loop Policy' \
  'post-PR `review-analysis` batching remains out of scope' \
  'The numbered sequence above is one bounded pass.' \
  'batch all clear-cut findings from one review pass' \
  'Mechanical corrections stay in the current loop' \
  'Semantic or user-directed changes start a new Standards/Spec review' \
  're-enters at the narrowest applicable gate' \
  'unchanged checks remain valid' \
  'does not weaken required quality, documentation, security, or final test gates' \
  'Correct the mechanical failure, rerun `check`' \
  'Correct the failure and rerun `check`' \
  'Rerun `test` after a test-only or mechanical correction' \
  'Correct the gate-specific issue and rerun the commit gate' \
  '| Initial `check` failure | Correct the mechanical failure, rerun `check`, then continue to Standards/Spec review |' \
  '| Standards/Spec review findings | Apply one correction batch, then run the corrective `check` |' \
  '| Corrective `check` failure | Correct the failure and rerun `check` |' \
  '| Final `test` failure | Rerun `test` after a test-only or mechanical correction; start Standards/Spec review after a behavioral correction |' \
  '| Commit-gate failure | Correct the gate-specific issue and rerun the commit gate |' \
  '`check` consumes the tracked repository; Standards/Spec review consumes the issue or spec and behavioral diff; `test` consumes source and test behavior; and the commit gate consumes staged content and commit metadata.' \
  'If any local gate cannot be resolved under this policy, stop' \
  'Automatic selection includes only open issues labeled `triage:for-agent`.' \
  'Exclude `triage:pending`, `triage:unanswered`, unlabeled, `triage:for-human`, and `triage:wontfix` issues.' \
  'Query open `triage:pending` issues separately and report them in a `requires triage` section.' \
  'If none, use the assigned-to-@me fallback, still requiring `triage:for-agent` and no open blockers.' \
  'If no eligible issue remains, report that no implementation-ready issue exists and stop without claiming one.' \
  'An issue is unblocked only when every issue in its `blockedBy` relationship is closed.' \
  'Inspect each blocker state; closed links do not block selection, while any open blocker excludes the candidate.'
assert_not_contains "$implement_skill" 'If any local gate fails, stop without committing, pushing, or closing the ticket'

assert_unblocked_by_state '[{"state":"CLOSED"},{"state":"CLOSED"}]' true
assert_unblocked_by_state '[{"state":"CLOSED"},{"state":"OPEN"}]' false
assert_not_contains "$implement_skill" 'Unassigned and unblocked — sort by priority then age.'
assert_not_contains "$implement_skill" 'If none, assigned to @me and unblocked.'

assert_contains_many "$code_review_skill" \
  'The caller may narrow the review scope to named axes.' \
  'when `implement` requests `Standards and Spec`, skip' \
  'one `subagent` tool call for each requested axis' \
  'omit the unrequested axes' \
  'Requested axes run as **parallel sub-agents**'

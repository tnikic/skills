#!/usr/bin/env bash
set -euo pipefail

TEST_CONCERN=skill-workflow
# shellcheck source=test_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/test_helpers.sh"

assert_file "$implement_skill"
assert_file "$capture_skill"
assert_file "$implement_skill_work"
assert_file "$improve_skill"
assert_file "$review_skill"
assert_file "$code_review_skill"

assert_contains_many "$implement_skill_work" \
  'name: implement-skill' \
  'disable-model-invocation: true' \
  'writing-for-agents' \
  'command-runner.md' \
  '## 1. Establish the contract' \
  '## 4. Verify'

assert_contains_many "$capture_skill" \
  'All forge calls follow the recipes' \
  'matching forge skill' \
  'does not run forge commands directly'
assert_not_contains "$capture_skill" 'gh issue create'
assert_not_contains "$capture_skill" 'gh label create'
assert_not_contains "$capture_skill" 'glab issue create'
assert_not_contains "$capture_skill" 'glab label create'

assert_contains_many "$improve_skill" \
  'name: improve-skill' \
  'disable-model-invocation: true' \
  'writing-for-agents' \
  'command-runner.md' \
  'If the user names no skill, run a portfolio scan:' \
  'Inventory every skill directory under `skills/`' \
  'Run the lightweight audits in parallel' \
  'Do not edit during the scan.' \
  '## 2. Explore the skill' \
  '## 3. Present candidates' \
  'Do not edit until the user picks a candidate.'

assert_contains_many "$review_skill" \
  'name: review-skill' \
  'command-runner.md' \
  'Standards' \
  'Spec' \
  'Coverage' \
  'Use fresh parallel review agents' \
  'Do not edit the skill'

assert_contains "$code_review_skill" 'command-runner.md'
assert_not_contains "$code_review_skill" 'make lint'
assert_not_contains "$code_review_skill" 'make fmt'
assert_not_contains "$code_review_skill" 'make check'

for skill in "$implement_skill_work" "$improve_skill" "$review_skill"; do
  assert_not_contains "$skill" 'make check'
  assert_not_contains "$skill" 'make test'
done

assert_contains_many "$implement_skill" \
  'Treat the issue body as the canonical source for body checkboxes.' \
  'Update the original issue body in place' \
  'preserving all unrelated text and replacing only satisfied' \
  'Record each criterion only in its source container.' \
  'edit the original comment in place via the forge skill' \
  'comment-edit recipe' \
  'body criteria remain in the issue body' \
  'every satisfied comment-only criterion is checked in its source comment' \
  'Automatic selection includes only open issues labeled `triage:for-agent`.' \
  'Exclude `triage:pending`, `triage:unanswered`, unlabeled, `triage:for-human`, and `triage:wontfix` issues.' \
  'Query open `triage:pending` issues separately and report them in a `requires triage` section.' \
  'If none, use the assigned-to-@me fallback, still requiring `triage:for-agent` and no open blockers.' \
  'If no eligible issue remains, report that no implementation-ready issue exists and stop without claiming one.' \
  'An issue is unblocked only when every issue in its `blockedBy` relationship is closed.' \
  'Inspect each blocker state; closed links do not block selection, while any open blocker excludes the candidate.'

assert_not_contains "$implement_skill" 'Unassigned and unblocked — sort by priority then age.'
assert_not_contains "$implement_skill" 'If none, assigned to @me and unblocked.'

assert_unblocked_by_state() {
  local blockers="$1"
  local expected="$2"
  local actual
  actual="$(jq -r 'all(.[]; .state == "CLOSED")' <<< "$blockers")"
  [ "$actual" = "$expected" ] || fail "blocker state resolved to $actual, expected $expected"
}

assert_unblocked_by_state '[{"state":"CLOSED"},{"state":"CLOSED"}]' true
assert_unblocked_by_state '[{"state":"CLOSED"},{"state":"OPEN"}]' false

assert_contains_many "$code_review_skill" \
  'Three-axis review of the diff' \
  'Standards' \
  'Spec' \
  'Coverage' \
  'All three axes run as **parallel sub-agents**'

printf 'skill-workflow: ok\n'

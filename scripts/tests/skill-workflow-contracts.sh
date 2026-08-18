#!/usr/bin/env bash
set -euo pipefail

TEST_CONCERN=skill-workflow
# shellcheck source=test_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/test_helpers.sh"

assert_file "$implement_skill"
assert_file "$code_review_skill"

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

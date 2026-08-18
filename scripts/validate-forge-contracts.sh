#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
contract="$repo_root/skills/shared/forge-pr-status-contract.md"
github_skill="$repo_root/skills/engineering/github/SKILL.md"
gitlab_skill="$repo_root/skills/engineering/gitlab/SKILL.md"

assert_file() {
  [ -f "$1" ] || {
    printf 'forge-contracts: missing file %s\n' "$1" >&2
    exit 1
  }
}

assert_contains() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || {
    printf 'forge-contracts: %s is missing %s\n' "$file" "$text" >&2
    exit 1
  }
}

assert_not_contains() {
  local file="$1"
  local text="$2"
  ! grep -Fq -- "$text" "$file" || {
    printf 'forge-contracts: %s unexpectedly contains %s\n' "$file" "$text" >&2
    exit 1
  }
}

assert_file "$contract"
assert_file "$github_skill"
assert_file "$gitlab_skill"

for operation in create_pr get_pr assign_reviewer list_review_comments \
  reply_and_mark_processed discover_required_checks status_for_head; do
  assert_contains "$contract" "\`$operation\`"
  assert_contains "$github_skill" "$operation"
  assert_contains "$gitlab_skill" "$operation"
done

for outcome in pending success failure cancelled stale timeout configuration-gap; do
  assert_contains "$contract" "\`$outcome\`"
  assert_contains "$github_skill" "$outcome"
  assert_contains "$gitlab_skill" "$outcome"
done

assert_contains "$contract" '[review-analysis processed:<batch-id>]'
assert_contains "$github_skill" '[review-analysis processed:$BATCH_ID]'
assert_contains "$gitlab_skill" '[review-analysis processed:$BATCH_ID]'
assert_contains "$contract" 'head SHA'
assert_contains "$github_skill" 'head SHA'
assert_contains "$gitlab_skill" 'head SHA'
assert_contains "$contract" 'raw: check-runs for head abc123'
assert_contains "$contract" 'raw: newest pipeline for SHA abc123'
assert_contains "$contract" 'Status Matrix'
assert_contains "$github_skill" '/rulesets?per_page=100'
assert_contains "$github_skill" 'processed=true'
assert_contains "$gitlab_skill" 'glab mr note create N -R $R --reply DISCUSSION_ID'
assert_contains "$gitlab_skill" 'processed=true'
assert_contains "$gitlab_skill" 'newest pipeline created for the requested SHA'
assert_not_contains "$contract" 'gh '
assert_not_contains "$contract" 'glab '

printf 'forge-contracts: ok\n'

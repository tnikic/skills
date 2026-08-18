#!/usr/bin/env bash
set -euo pipefail

TEST_CONCERN=forge-adapter
# shellcheck source=test_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/test_helpers.sh"

assert_file "$github_skill"
assert_file "$gitlab_skill"
assert_file "$forge_contract"

assert_adapter_find_pr() {
  local skill="$1"
  local one_fixture="$2"
  local expected="$3"
  local duplicate_fixture="$4"
  local filter actual
  filter="$(awk '
    /# find_pr/ { in_find = 1; next }
    in_find && /--jq/ {
      line = $0
      sub(/^.*--jq /, "", line)
      sub(/^\047/, "", line)
      sub(/\047$/, "", line)
      print line
      exit
    }
  ' "$skill")"
  [ -n "$filter" ] || fail "$skill has no find_pr filter"
  actual="$(jq -c "$filter" <<< '[]')"
  [ -z "$actual" ] || fail "$skill find_pr returned a no-match value"
  actual="$(jq -c "$filter" <<< "$one_fixture")"
  [ "$actual" = "$expected" ] || fail "$skill find_pr returned $actual"
  if jq -c "$filter" <<< "$duplicate_fixture" >/dev/null 2>&1; then
    fail "$skill find_pr accepted duplicate matches"
  fi
}

assert_adapter_find_pr "$github_skill" \
  '[{"number":55,"url":"https://example.test/55","state":"OPEN","baseRefName":"main","headRefName":"feat/55-pr-delivery-contracts","headRefOid":"abc123"}]' \
  '{"number":55,"url":"https://example.test/55","state":"OPEN","base_branch":"main","head_branch":"feat/55-pr-delivery-contracts","head_sha":"abc123"}' \
  '[{"number":55},{"number":59}]'
assert_adapter_find_pr "$gitlab_skill" \
  '[{"iid":55,"web_url":"https://example.test/55","state":"opened","target_branch":"main","source_branch":"feat/55-pr-delivery-contracts","sha":"abc123"}]' \
  '{"number":55,"url":"https://example.test/55","state":"opened","base_branch":"main","head_branch":"feat/55-pr-delivery-contracts","head_sha":"abc123"}' \
  '[{"iid":55},{"iid":59}]'
assert_contains_many "$github_skill" \
  'gh api -X GET "/repos/$R/commits/$HEAD_SHA/check-runs?per_page=100"' \
  'configuration-gap' \
  'native stack behavior' \
  'gh pr list -R $R --head HEADBRANCH --state open' \
  'if length > 1 then error' \
  'elif length == 0 then empty' \
  'gh pr edit N -R $R --base "$BASE_BRANCH"' \
  'gh pr create -R $R' \
  'gh repo view -R $R --json defaultBranchRef' \
  '--base "$BASE_BRANCH"' \
  'PR_URL="$(gh pr create' \
  "--jq '{number,url,state,base_branch:.baseRefName,head_branch:.headRefName,head_sha:.headRefOid}'" \
  'gh pr edit N -R $R --add-reviewer REVIEWER' \
  'review-analysis processed:$BATCH_ID'
assert_contains "$github_skill" "gh api \"/repos/\$R/issues/comments/COMMENT_ID\" --jq '.body'"

assert_contains "$github_skill" 'gh api --method PATCH "/repos/$R/issues/comments/COMMENT_ID" -f body="COMPLETE_UPDATED_BODY"'

assert_contains_many "$gitlab_skill" \
  'glab api "projects/GROUP%2FREPO/issues/N/notes?activity_filter=only_comments" --paginate' \
  'glab api -X PUT "projects/GROUP%2FREPO/issues/N/notes/COMMENT_ID" -f body="COMPLETE_UPDATED_BODY"' \
  'glab mr create -R $R' \
  'glab api "projects/GROUP%2FREPO"' \
  'default_branch' \
  '| jq -r' \
  '-b "$BASE_BRANCH"' \
  'MR_URL="$(glab mr create' \
  "--jq '{number:.iid,url:.web_url,state,base_branch:.target_branch,head_branch:.source_branch,head_sha:.sha}'" \
  'glab mr update N -R $R --reviewer REVIEWER' \
  'pipelines?sha=$HEAD_SHA' \
  'configuration-gap' \
  'native stack behavior' \
  'glab mr list -R $R --source-branch SOURCE_BRANCH -F json' \
  'if length > 1 then error' \
  'elif length == 0 then empty' \
  'glab mr update N -R $R --target-branch "$BASE_BRANCH"' \
  'review-analysis processed:$BATCH_ID'

assert_contains_many "$forge_contract" \
  '## Normalized Operations' \
  'create_pr' \
  'find_pr' \
  'update_pr' \
  'retarget_pr' \
  'discover_required_checks' \
  'status_for_head' \
  '`pending`' \
  '`success`' \
  '`failure`' \
  '`cancelled`' \
  '`stale`' \
  '`timeout`' \
  '`configuration-gap`' \
  'review-analysis processed:'

bash "$repo_root/scripts/validate-forge-contracts.sh"
bash "$repo_root/scripts/validate-pr-contracts.sh"

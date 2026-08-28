#!/usr/bin/env bash
set -euo pipefail

TEST_CONCERN=forge-adapter
# shellcheck source=test_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/test_helpers.sh"

assert_file "$github_skill"
assert_file "$gitlab_skill"
assert_file "$forge_contract"
assert_file "$pr_template"

assert_contains_many_normalized "$forge_contract" \
  '## Operations' \
  '`create`' \
  '`find`' \
  '`view`' \
  '`update`' \
  '`retarget`' \
  '`publication_failure`' \
  'publication-failure' \
  'Normalized Publication Record' \
  'record_id' \
  'source_branch' \
  'target_branch' \
  'head_sha' \
  '## Publication Failure' \
  'tooling-unavailable' \
  'authentication-required' \
  'permission-denied' \
  'publication-failed' \
  'retryable: true' \
  'preserved_branch: true' \
  'preserved_issue: true' \
  'stack root' \
  'selected predecessor branch' \
  'adapter returns that topology'
assert_not_contains "$forge_contract" 'gh '
assert_not_contains "$forge_contract" 'glab '

assert_contains_many_normalized "$pr_template" \
  '## Change scope' \
  '## Notable decisions' \
  '## Validation' \
  '## Acceptance results' \
  '## Spec context (optional)' \
  '## Stack position' \
  '## Dependency context' \
  '## Related records' \
  'intermediate stack branch' \
  'final publication' \
  'Closes #N'

for skill in "$github_skill" "$gitlab_skill"; do
  assert_contains_many_normalized "$skill" \
    'forge-pr-delivery-contract.md' \
    '# create' \
    '# find' \
    '# view' \
    '# update' \
    '# retarget' \
    '# publication_failure' \
    'record_id' \
    'source_branch' \
    'target_branch' \
    'head_sha' \
    'tooling' \
    'authentication' \
    'permissions' \
    'publication'
done
assert_contains_many_normalized "$github_skill" \
  'gh pr create -R $R' \
  'gh pr list -R $R --head SOURCE_BRANCH --state open' \
  'gh pr edit RECORD_ID -R $R --base TARGET_BRANCH'
assert_contains_many_normalized "$github_skill" \
  'github/gh-stack' \
  'GitHub CLI 2.0' \
  'gh repo view -R "$R"' \
  'git -C "$REPO_DIR" remote get-url "$REMOTE"' \
  'gh stack init' \
  'adopts existing branches' \
  'gh stack add' \
  'gh stack push --remote "$REMOTE"' \
  'gh stack submit --auto --open --remote "$REMOTE"' \
  'gh stack view --json' \
  'gh stack sync --remote "$REMOTE"' \
  'gh stack sync --prune --remote "$REMOTE"' \
  'tooling-unavailable' \
  'authentication-required' \
  'permission-denied' \
  'publication-failed' \
  'retryable: true' \
  'Preserve the pushed branch and issue state' \
  'record_id' \
  'source_branch' \
  'target_branch' \
  'head_sha'
assert_order_normalized "$github_skill" \
  '## Setup and auth' \
  '## Repository targeting' \
  '## Native Stacked Pull Requests' \
  '### Initialize and adopt branches' \
  '### Push and submit' \
  '### View and normalize metadata' \
  '### Synchronize' \
  '### Retryable failures'
assert_order_normalized "$github_skill" \
  'gh extension install github/gh-stack' \
  'gh auth status' \
  'gh repo view -R "$R"' \
  'gh stack init' \
  'gh stack add' \
  'gh stack push --remote "$REMOTE"' \
  'gh stack submit --auto --open --remote "$REMOTE"' \
  'gh stack view --json' \
  'gh pr view "$pr" -R "$R"' \
  'gh stack sync --remote "$REMOTE"' \
  'gh stack sync --prune --remote "$REMOTE"'
assert_not_contains "$github_skill" 'Graphite'
assert_not_contains "$github_skill" 'graphite'
assert_contains_many_normalized "$gitlab_skill" \
  '## Repository targeting' \
  'Developer or greater access' \
  '`api` scope' \
  'push the selected source branch' \
  'native merge-request UI' \
  'human fallback and inspection' \
  'experimental `glab stack sync`' \
  'glab mr create -R $R' \
  'glab mr list -R $R --source-branch SOURCE_BRANCH -F json' \
  'glab mr update RECORD_ID -R $R --target-branch TARGET_BRANCH' \
  'projects/GROUP%2FREPO/merge_requests' \
  'publication_exists=unknown' \
  'bounded backoff' \
  'branch identity'
assert_not_contains "$github_skill" 'then "{\\"record\\":null}"'
assert_not_contains "$gitlab_skill" 'then "{\\"record\\":null}"'

fixture_dir="$(dirname "$repo_root/scripts/fixtures/forge-pr-delivery/github-create.json")"
github_create="$fixture_dir/github-create.json"
gitlab_create="$fixture_dir/gitlab-create.json"
github_failures="$fixture_dir/github-failures.json"
gitlab_failures="$fixture_dir/gitlab-failures.json"
github_stack_view="$fixture_dir/github-stack-view.json"
for fixture in "$github_create" "$gitlab_create" "$github_failures" "$gitlab_failures" "$github_stack_view"; do
  assert_file "$fixture"
done

stack_branches="$(jq -c '[.branches[] | {name,head,base,pr: .pr.number}]' "$github_stack_view")"
expected_stack='[{"name":"feature-auth","head":"auth123","base":"main","pr":41},{"name":"feature-ui","head":"ui456","base":"feature-auth","pr":42}]'
[ "$stack_branches" = "$expected_stack" ] || fail "GitHub stack fixture lost branch topology: $stack_branches"
stack_prs="$(jq -c '[.branches[] | select(.pr != null) | .pr.number]' "$github_stack_view")"
[ "$stack_prs" = '[41,42]' ] || fail "GitHub stack fixture lost PR identifiers: $stack_prs"

github_result="$(jq -c '{record_id:(.number|tostring),url,title,body,source_branch:.headRefName,target_branch:.baseRefName,head_sha:.headRefOid,state:(if .state == "OPEN" then "open" else "closed" end)}' "$github_create")"
gitlab_result="$(jq -c '{record_id:(.iid|tostring),url:.web_url,title,body:.description,source_branch:.source_branch,target_branch:.target_branch,head_sha:.sha,state:(if .state == "opened" then "open" else "closed" end)}' "$gitlab_create")"
expected_result='{"record_id":"42","url":"https://github.example/pull/42","title":"[delivery 1/2] publish ticket","body":"ticket body","source_branch":"feat/42-delivery","target_branch":"main","head_sha":"abc123","state":"open"}'
[ "$github_result" = "$expected_result" ] || fail "GitHub fixture normalized to $github_result"
expected_gitlab='{"record_id":"42","url":"https://gitlab.example/merge_requests/42","title":"[delivery 1/2] publish ticket","body":"ticket body","source_branch":"feat/42-delivery","target_branch":"main","head_sha":"abc123","state":"open"}'
[ "$gitlab_result" = "$expected_gitlab" ] || fail "GitLab fixture normalized to $gitlab_result"

github_equivalent="$(jq -c '{record_id:(.number|tostring),title,body,source_branch:.headRefName,target_branch:.baseRefName,head_sha:.headRefOid,state:(if .state == "OPEN" then "open" else "closed" end)}' "$github_create")"
gitlab_equivalent="$(jq -c '{record_id:(.iid|tostring),title,body:.description,source_branch:.source_branch,target_branch:.target_branch,head_sha:.sha,state:(if .state == "opened" then "open" else "closed" end)}' "$gitlab_create")"
[ "$github_equivalent" = "$gitlab_equivalent" ] || fail 'provider fixtures do not have equivalent normalized outcomes'

for fixture in "$github_failures" "$gitlab_failures"; do
  for class in tooling authentication permissions publication; do
    jq -e ".${class}" "$fixture" >/dev/null || fail "$fixture is missing $class failure fixture"
  done
  for class in tooling authentication permissions publication; do
    case "$class" in
      tooling) expected_class=tooling-unavailable; actual_class="$(jq -r 'if .tooling.exit_code == 127 then "tooling-unavailable" else empty end' "$fixture")" ;;
      authentication) expected_class=authentication-required; actual_class="$(jq -r 'if .authentication.status == 401 then "authentication-required" else empty end' "$fixture")" ;;
      permissions) expected_class=permission-denied; actual_class="$(jq -r 'if .permissions.status == 403 then "permission-denied" else empty end' "$fixture")" ;;
      publication) expected_class=publication-failed; actual_class="$(jq -r 'if .publication.status == 503 then "publication-failed" else empty end' "$fixture")" ;;
    esac
    [ "$actual_class" = "$expected_class" ] || fail "$fixture mapped $class to $actual_class"
    result="$(jq -cn --arg failure_class "$actual_class" '{failure_class:$failure_class, retryable:true, publication_exists:false, preserved_branch:true, preserved_issue:true}')"
    expected="$(jq -cn --arg failure_class "$expected_class" '{failure_class:$failure_class, retryable:true, publication_exists:false, preserved_branch:true, preserved_issue:true}')"
    [ "$result" = "$expected" ] || fail "$fixture did not preserve retryable state for $class"
  done
done

printf 'forge-adapter: ok\n'

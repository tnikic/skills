#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
makefile="$repo_root/Makefile"
workflow="$repo_root/.github/workflows/ci.yml"
readme="$repo_root/README.md"
implement_skill="$repo_root/skills/engineering/implement/SKILL.md"
code_review_skill="$repo_root/skills/engineering/code-review/SKILL.md"
github_skill="$repo_root/skills/engineering/github/SKILL.md"
gitlab_skill="$repo_root/skills/engineering/gitlab/SKILL.md"
forge_contract="$repo_root/skills/shared/forge-pr-status-contract.md"

fail() {
  printf 'test: %s\n' "$1" >&2
  exit 1
}

assert_file() {
  [ -f "$1" ] || fail "missing file $1"
}

assert_contains() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || fail "$file is missing $text"
}

assert_not_contains() {
  local file="$1"
  local text="$2"
  ! grep -Fq -- "$text" "$file" || fail "$file unexpectedly contains $text"
}

assert_order() {
  local file="$1"
  shift
  local previous=0
  local text line
  for text in "$@"; do
    line="$(awk -v text="$text" -v previous="$previous" 'NR > previous && index($0, text) { print NR; exit }' "$file")"
    [ -n "$line" ] || fail "$file is missing ordered step $text"
    [ "$line" -gt "$previous" ] || fail "$file has out-of-order step $text"
    previous="$line"
  done
}

assert_job_runs() {
  local job="$1"
  local command="$2"
  awk -v job="$job" -v command="$command" '
    $0 == "  " job ":" { in_job = 1; next }
    in_job && $0 ~ /^  [^ ]/ { if (found) exit 0; exit 1 }
    in_job && $0 == "      - run: " command { found = 1 }
    END { if (in_job && found) exit 0; exit 1 }
  ' "$workflow" || fail "workflow job $job does not run $command"
}

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
assert_delivery_branch combined feat/pr-delivery-contracts
assert_delivery_branch stacked feat/55-pr-delivery-contracts
assert_delivery_branch per-ticket feat/55-pr-delivery-contracts

assert_file "$makefile"
assert_file "$workflow"
assert_file "$readme"
assert_file "$implement_skill"
assert_file "$code_review_skill"
assert_file "$github_skill"
assert_file "$gitlab_skill"
assert_file "$forge_contract"

make_targets="$(make -qp -f "$makefile" 2>/dev/null || true)"
grep -Eq '^check($|[[:space:]]*:)' <<<"$make_targets" ||
  fail 'Makefile does not define check'
grep -Eq '^test($|[[:space:]]*:)' <<<"$make_targets" ||
  fail 'Makefile does not define test'

make_test_recipe="$(make -n -f "$makefile" test)"
grep -Fq -- './scripts/test.sh' <<<"$make_test_recipe" ||
  fail 'test target does not run scripts/test.sh'

temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT

managed_bin="$temporary_dir/managed-bin"
runner_bin="$temporary_dir/runner-bin"
managed_tool_log="$temporary_dir/managed-tools.log"
mise_log="$temporary_dir/mise.log"
mkdir -p "$managed_bin" "$runner_bin"

for tool in gitleaks lychee; do
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'printf "%s %s\n" "$0" "$*" >> "$TOOL_LOG"' \
    > "$managed_bin/$tool"
  chmod +x "$managed_bin/$tool"
done

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'printf "%s\n" "$*" >> "$MISE_LOG"' \
  '[ "$1" = exec ] && [ "$2" = -- ] || exit 1' \
  'shift 2' \
  'PATH="$MANAGED_BIN:$PATH" "$@"' \
  > "$runner_bin/mise"
chmod +x "$runner_bin/mise"

if ! PATH="$runner_bin:/usr/bin:/bin" MANAGED_BIN="$managed_bin" MISE_LOG="$mise_log" TOOL_LOG="$managed_tool_log" \
  make -f "$makefile" check >/dev/null 2>&1; then
  fail 'check target could not run tools supplied by mise'
fi
grep -Fq -- 'exec -- gitleaks detect --no-git' "$mise_log" ||
  fail 'check target did not invoke gitleaks through mise'
grep -Fq -- 'exec -- lychee --offline --no-progress --exclude-path' "$mise_log" ||
  fail 'check target did not invoke lychee through mise'
grep -Fq -- "$managed_bin/gitleaks" "$managed_tool_log" ||
  fail 'mise did not supply gitleaks to check'
grep -Fq -- "$managed_bin/lychee" "$managed_tool_log" ||
  fail 'mise did not supply lychee to check'

direct_bin="$temporary_dir/direct-bin"
direct_tool_log="$temporary_dir/direct-tools.log"
mkdir -p "$direct_bin"
for tool in gitleaks lychee; do
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'printf "%s %s\n" "$0" "$*" >> "$TOOL_LOG"' \
    > "$direct_bin/$tool"
  chmod +x "$direct_bin/$tool"
done

if ! PATH="$direct_bin:/usr/bin:/bin" TOOL_LOG="$direct_tool_log" \
  make -f "$makefile" MISE= check >/dev/null 2>&1; then
  fail 'check target could not run without mise'
fi
grep -Fq -- "$direct_bin/gitleaks" "$direct_tool_log" ||
  fail 'fallback check did not run gitleaks directly'
grep -Fq -- "$direct_bin/lychee" "$direct_tool_log" ||
  fail 'fallback check did not run lychee directly'

if missing_suite_output="$(cd "$temporary_dir" && make -f "$makefile" test 2>&1)"; then
  fail 'missing test suite unexpectedly passed'
fi
grep -Fq -- 'test: no executable test suite found at scripts/test.sh' <<<"$missing_suite_output" ||
  fail 'missing test suite does not produce a meaningful failure'

assert_contains "$workflow" 'pull_request:'
assert_job_runs check 'make check'
assert_job_runs test 'make test'
assert_contains "$readme" '## Quality gates'
assert_contains "$readme" 'authoritative merge gate'
assert_contains "$readme" 'required status checks'
assert_contains "$implement_skill" 'Treat the issue body as the canonical source for body checkboxes.'
assert_contains "$implement_skill" 'Update the original issue body in place'
assert_contains "$implement_skill" 'preserving all unrelated text and replacing only satisfied'
assert_contains "$implement_skill" 'Record each criterion only in its source container.'
assert_contains "$implement_skill" 'edit the original comment in place via the forge skill'
assert_contains "$implement_skill" 'comment-edit recipe'
assert_contains "$implement_skill" 'body criteria remain in the issue body'
assert_contains "$implement_skill" 'every satisfied comment-only criterion is checked in its source comment'
assert_not_contains "$implement_skill" 'leave the source comment unchanged'
assert_not_contains "$implement_skill" 'post one concise comment listing the satisfied criteria and their source comment'
assert_not_contains "$implement_skill" 'For each satisfied criterion, replace `- [ ]` with `- [x]` and update the issue body via the forge skill'
assert_contains "$implement_skill" 'Read the originating spec delivery mode from the shared [delivery contracts]'
assert_contains "$implement_skill" 'Derive `<type>` from the ticket'
assert_contains "$implement_skill" 'For the default per-ticket mode, if the current branch already matches'
assert_contains "$implement_skill" 'Otherwise create or switch to that branch before continuing.'
assert_contains "$implement_skill" 'Invoke `/code-review` with the scope `Standards and Spec`'
assert_contains "$implement_skill" 'complete working-tree diff from the branch merge-base'
assert_contains "$implement_skill" 'Coverage remains owned by `improve-codebase-architecture`'
assert_contains "$implement_skill" 'Do not derive `Closes` or `Refs` metadata from branch names'
assert_contains "$implement_skill" 'leave the ticket open and assigned'
assert_contains "$implement_skill" 'judgment-dependent finding'
assert_contains "$implement_skill" 'universal commit-quality and documentation gate'
assert_contains "$implement_skill" 'After `/commit` succeeds, push the Conventional Branch with `git push -u origin HEAD`.'
assert_contains "$implement_skill" 'Render the PR body from the shared [PR template]'
assert_contains "$implement_skill" 'Add `Closes #N` as the final relationship footer.'
assert_contains "$implement_skill" 'Apply the declared `impact` value, defaulting to `impact:normal`'
assert_contains "$implement_skill" 'while keeping the ticket open'
assert_contains "$implement_skill" 'Use the forge issue-edit recipe to transfer the'
assert_contains "$implement_skill" 'Assign `HUMAN_REVIEWER` and request review'
assert_contains "$implement_skill" 'closes only when the PR merges through its `Closes #N` relationship.'
assert_contains "$implement_skill" 'matching forge skill'
assert_contains "$implement_skill" '`find_pr`, `create_pr`,'
assert_contains "$implement_skill" '`update_pr` recipe'
assert_contains "$implement_skill" 'then use `update_pr` and push incrementally'
assert_contains "$implement_skill" '`retarget_pr` when the predecessor merges to the default branch'
assert_contains "$implement_skill" 'first ticket in the spec'
assert_contains "$implement_skill" 'read its body and all tickets in'
assert_contains "$implement_skill" 'render the cumulative changes'
assert_contains "$implement_skill" 'More than one match is an error.'
assert_contains "$implement_skill" '`assign_reviewer` recipe'
assert_contains "$implement_skill" 'Require `HUMAN_REVIEWER` as explicit workflow input.'
assert_contains "$implement_skill" 'Read it from the invocation context or ask the user.'
assert_contains "$implement_skill" 'ask the user'
assert_contains "$implement_skill" 'Never substitute the agent identity for the human reviewer.'
assert_contains "$implement_skill" 'forge issue-edit recipe'
assert_contains "$implement_skill" 'current branch as `head`'
assert_contains "$implement_skill" 'repository default branch as `base`'
assert_contains "$implement_skill" 'provisional `[<spec-slug> <n>/<N>] <summary>` title form'
assert_contains "$implement_skill" 'Each recipe'
assert_contains "$implement_skill" 'Pass the PR number and current head SHA to the exact-head readiness workflow'
assert_contains "$implement_skill" '`discover_required_checks`'
assert_contains "$implement_skill" 'maps `status_for_head` success for that exact SHA'
assert_contains "$implement_skill" 'Stop only after that workflow reports the PR ready'
assert_contains "$implement_skill" 'leaves the PR open and not ready'
assert_contains "$implement_skill" 'The default path is one per-ticket branch and one PR for this ticket.'
assert_contains "$implement_skill" 'Combined and stacked paths are opt-in and leave the default path unchanged.'
assert_contains "$implement_skill" 'Read the originating spec delivery mode'
assert_contains "$implement_skill" '`delivery: combined`'
assert_contains "$implement_skill" '`delivery: stacked`'
assert_contains "$implement_skill" 'incremental pushes'
assert_contains "$implement_skill" 'previous stack branch as `base`'
assert_contains "$implement_skill" 'Retarget the PR through the forge skill'
assert_contains "$implement_skill" 'Post-merge parent check'
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
assert_order "$implement_skill" \
  'Create or adopt the Conventional Branch before editing tracked files' \
  '1. Run the project `check` target.' \
  '2. Invoke `/code-review` with the scope `Standards and Spec`' \
  '3. Fix clear-cut review findings.' \
  '4. Run the project `check` target again after corrections.' \
  '5. Run the project `test` target once at the end of the implementation loop.' \
  '6. Invoke `/commit` as the universal commit-quality and documentation gate.' \
  'If any local gate fails, stop without committing, pushing, or closing the ticket' \
  'A judgment-dependent finding has the same outcome'
assert_contains "$code_review_skill" 'The caller may narrow the review scope to named axes.'
assert_contains "$code_review_skill" 'when `implement` requests `Standards and Spec`, skip'
assert_contains "$code_review_skill" 'one `subagent` tool call for each requested axis'
assert_contains "$code_review_skill" 'omit the unrequested axes'
assert_contains "$code_review_skill" 'Requested axes run as **parallel sub-agents**'
assert_contains "$implement_skill" 'Automatic selection includes only open issues labeled `triage:for-agent`.'
assert_contains "$implement_skill" 'Exclude `triage:pending`, `triage:unanswered`, unlabeled, `triage:for-human`, and `triage:wontfix` issues.'
assert_contains "$implement_skill" 'Query open `triage:pending` issues separately and report them in a `requires triage` section.'
assert_contains "$implement_skill" 'If none, use the assigned-to-@me fallback, still requiring `triage:for-agent` and no open blockers.'
assert_contains "$implement_skill" 'If no eligible issue remains, report that no implementation-ready issue exists and stop without claiming one.'
assert_contains "$implement_skill" 'An issue is unblocked only when every issue in its `blockedBy` relationship is closed.'
assert_contains "$implement_skill" 'Inspect each blocker state; closed links do not block selection, while any open blocker excludes the candidate.'
assert_not_contains "$implement_skill" 'Unassigned and unblocked — sort by priority then age.'
assert_not_contains "$implement_skill" 'If none, assigned to @me and unblocked.'
assert_unblocked_by_state '[{"state":"CLOSED"},{"state":"CLOSED"}]' true
assert_unblocked_by_state '[{"state":"CLOSED"},{"state":"OPEN"}]' false
assert_contains "$github_skill" 'gh api "/repos/$R/issues/comments/COMMENT_ID" --jq '\''.body'\'''
assert_contains "$github_skill" 'gh api --method PATCH "/repos/$R/issues/comments/COMMENT_ID" -f body="COMPLETE_UPDATED_BODY"'
assert_contains "$gitlab_skill" 'glab api "projects/GROUP%2FREPO/issues/N/notes?activity_filter=only_comments" --paginate'
assert_contains "$gitlab_skill" 'glab api -X PUT "projects/GROUP%2FREPO/issues/N/notes/COMMENT_ID" -f body="COMPLETE_UPDATED_BODY"'

assert_contains "$forge_contract" '## Normalized Operations'
assert_contains "$forge_contract" 'create_pr'
assert_contains "$forge_contract" 'find_pr'
assert_contains "$forge_contract" 'update_pr'
assert_contains "$forge_contract" 'retarget_pr'
assert_contains "$forge_contract" 'discover_required_checks'
assert_contains "$forge_contract" 'status_for_head'
for outcome in pending success failure cancelled stale timeout configuration-gap; do
  assert_contains "$forge_contract" "\`$outcome\`"
done
assert_contains "$forge_contract" 'review-analysis processed:'
assert_contains "$github_skill" 'gh api -X GET "/repos/$R/commits/$HEAD_SHA/check-runs?per_page=100"'
assert_contains "$github_skill" 'configuration-gap'
assert_contains "$github_skill" 'native stack behavior'
assert_contains "$github_skill" 'gh pr list -R $R --head HEADBRANCH --state open'
assert_contains "$github_skill" 'if length > 1 then error'
assert_contains "$github_skill" 'elif length == 0 then empty'
assert_contains "$github_skill" 'gh pr edit N -R $R --base "$BASE_BRANCH"'
assert_contains "$github_skill" 'gh pr create -R $R'
assert_contains "$github_skill" 'gh repo view -R $R --json defaultBranchRef'
assert_contains "$github_skill" '--base "$BASE_BRANCH"'
assert_contains "$github_skill" 'PR_URL="$(gh pr create'
assert_contains "$github_skill" "--jq '{number,url,state,base_branch:.baseRefName,head_branch:.headRefName,head_sha:.headRefOid}'"
assert_contains "$github_skill" 'gh pr edit N -R $R --add-reviewer REVIEWER'
assert_contains "$github_skill" 'review-analysis processed:$BATCH_ID'
assert_contains "$gitlab_skill" 'glab mr create -R $R'
assert_contains "$gitlab_skill" 'glab api "projects/GROUP%2FREPO"'
assert_contains "$gitlab_skill" 'default_branch'
assert_contains "$gitlab_skill" '| jq -r'
assert_contains "$gitlab_skill" '-b "$BASE_BRANCH"'
assert_contains "$gitlab_skill" 'MR_URL="$(glab mr create'
assert_contains "$gitlab_skill" "--jq '{number:.iid,url:.web_url,state,base_branch:.target_branch,head_branch:.source_branch,head_sha:.sha}'"
assert_contains "$gitlab_skill" 'glab mr update N -R $R --reviewer REVIEWER'
assert_contains "$gitlab_skill" 'pipelines?sha=$HEAD_SHA'
assert_contains "$gitlab_skill" 'configuration-gap'
assert_contains "$gitlab_skill" 'native stack behavior'
assert_contains "$gitlab_skill" 'glab mr list -R $R --source-branch SOURCE_BRANCH -F json'
assert_contains "$gitlab_skill" 'if length > 1 then error'
assert_contains "$gitlab_skill" 'elif length == 0 then empty'
assert_contains "$gitlab_skill" 'glab mr update N -R $R --target-branch "$BASE_BRANCH"'
assert_contains "$gitlab_skill" 'review-analysis processed:$BATCH_ID'

bash "$repo_root/scripts/validate-forge-contracts.sh"

bash "$repo_root/scripts/validate-pr-contracts.sh"
printf 'test: ok\n'

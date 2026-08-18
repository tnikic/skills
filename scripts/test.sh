#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
makefile="$repo_root/Makefile"
workflow="$repo_root/.github/workflows/ci.yml"
readme="$repo_root/README.md"
implement_skill="$repo_root/skills/engineering/implement/SKILL.md"
github_skill="$repo_root/skills/engineering/github/SKILL.md"
gitlab_skill="$repo_root/skills/engineering/gitlab/SKILL.md"

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

assert_file "$makefile"
assert_file "$workflow"
assert_file "$readme"
assert_file "$implement_skill"
assert_file "$github_skill"
assert_file "$gitlab_skill"

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
assert_contains "$github_skill" 'gh api "/repos/$R/issues/comments/COMMENT_ID" --jq '\''.body'\'''
assert_contains "$github_skill" 'gh api --method PATCH "/repos/$R/issues/comments/COMMENT_ID" -f body="COMPLETE_UPDATED_BODY"'
assert_contains "$gitlab_skill" 'glab api "projects/GROUP%2FREPO/issues/N/notes?activity_filter=only_comments" --paginate'
assert_contains "$gitlab_skill" 'glab api -X PUT "projects/GROUP%2FREPO/issues/N/notes/COMMENT_ID" -f body="COMPLETE_UPDATED_BODY"'

bash "$repo_root/scripts/validate-pr-contracts.sh"
printf 'test: ok\n'

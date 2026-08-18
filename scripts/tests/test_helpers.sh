#!/usr/bin/env bash

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
makefile="$repo_root/Makefile"
workflow="$repo_root/.github/workflows/ci.yml"
readme="$repo_root/README.md"
test_runner="$repo_root/scripts/test.sh"
implement_skill="$repo_root/skills/engineering/implement/SKILL.md"
readiness_script="$repo_root/scripts/pr-readiness.sh"
code_review_skill="$repo_root/skills/engineering/code-review/SKILL.md"
review_analysis_skill="$repo_root/skills/engineering/review-analysis/SKILL.md"
github_skill="$repo_root/skills/engineering/github/SKILL.md"
gitlab_skill="$repo_root/skills/engineering/gitlab/SKILL.md"
forge_contract="$repo_root/skills/shared/forge-pr-status-contract.md"

fail() {
  printf 'test[%s]: %s\n' "${TEST_CONCERN:-unknown}" "$1" >&2
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

assert_contains_many() {
  local file="$1"
  shift
  local text
  for text in "$@"; do
    assert_contains "$file" "$text"
  done
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

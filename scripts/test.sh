#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
makefile="$repo_root/Makefile"
workflow="$repo_root/.github/workflows/ci.yml"
readme="$repo_root/README.md"

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

bash "$repo_root/scripts/validate-pr-contracts.sh"
printf 'test: ok\n'

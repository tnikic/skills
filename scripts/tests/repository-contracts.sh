#!/usr/bin/env bash
set -euo pipefail

TEST_CONCERN=repository
# shellcheck source=test_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/test_helpers.sh"

assert_file "$makefile"
assert_file "$readme"
assert_file "$context"
assert_file "$test_runner"
assert_file "$(dirname "$test_runner")/tests/test_helpers.sh"
assert_file "$(dirname "$test_runner")/tests/repository-contracts.sh"
assert_file "$(dirname "$test_runner")/tests/skill-workflow-contracts.sh"
assert_contains "$test_runner" 'scripts/tests/repository-contracts.sh'
assert_contains "$test_runner" 'scripts/tests/skill-workflow-contracts.sh'

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

assert_contains "$readme" '## Quality gates'
assert_contains "$makefile" 'lychee --offline --no-progress --exclude-path'
assert_contains "$makefile" 'README.md docs skills'

runner_fixture="$(mktemp -d)"
trap 'rm -rf "$temporary_dir" "$runner_fixture"' EXIT
mkdir -p "$runner_fixture/scripts/tests"
cp "$test_runner" "$runner_fixture/scripts/test.sh"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "test[repository]: fixture failure\\n" >&2' \
  'exit 1' \
  > "$runner_fixture/scripts/tests/repository-contracts.sh"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "test: skill-workflow fixture ran\\n"' \
  > "$runner_fixture/scripts/tests/skill-workflow-contracts.sh"
if runner_output="$(bash "$runner_fixture/scripts/test.sh" 2>&1)"; then
  fail 'runner returned success after a concern failed'
fi
assert_contains <(printf '%s\n' "$runner_output") 'test[repository]: fixture failure'
assert_contains <(printf '%s\n' "$runner_output") 'test: repository: failed'
assert_contains <(printf '%s\n' "$runner_output") 'test: skill-workflow fixture ran'

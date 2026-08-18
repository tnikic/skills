#!/usr/bin/env bash
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

suites=(
  repository "scripts/tests/repository-contracts.sh"
  skill-workflow "scripts/tests/skill-workflow-contracts.sh"
  forge-adapter "scripts/tests/forge-adapter-contracts.sh"
)

failed=0
for ((index = 0; index < ${#suites[@]}; index += 2)); do
  concern="${suites[index]}"
  suite="$repo_root/${suites[index + 1]}"
  if bash "$suite"; then
    printf 'test: %s: ok\n' "$concern"
  else
    printf 'test: %s: failed\n' "$concern" >&2
    failed=1
  fi
done

if [ "$failed" -ne 0 ]; then
  printf 'test: failed\n' >&2
  exit 1
fi

printf 'test: ok\n'

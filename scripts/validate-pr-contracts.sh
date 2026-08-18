#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template="$repo_root/skills/shared/pr-template.md"
contracts="$repo_root/skills/shared/pr-delivery-contracts.md"
commit_guidance="$repo_root/skills/engineering/conventional-commits/SKILL.md"

assert_contains() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || {
    printf 'contracts: %s is missing %s\n' "$file" "$text" >&2
    exit 1
  }
}

assert_matches() {
  local value="$1"
  local pattern="$2"
  [[ "$value" =~ $pattern ]] || {
    printf 'contracts: %s does not match %s\n' "$value" "$pattern" >&2
    exit 1
  }
}

assert_not_matches() {
  local value="$1"
  local pattern="$2"
  if [[ "$value" =~ $pattern ]]; then
    printf 'contracts: %s must not match %s\n' "$value" "$pattern" >&2
    exit 1
  fi
}

assert_contains "$template" '## What this does'
assert_contains "$template" '## Changes'
assert_contains "$template" '## Acceptance criteria'
assert_contains "$template" 'Closes #N'

assert_contains "$contracts" '<type>/<ticket-number>-<spec-slug>'
assert_contains "$contracts" '<type>/<spec-slug>'
assert_contains "$contracts" '[<spec-slug> <n>/<N>]'
assert_contains "$contracts" 'Merge-order numbers never appear in branch names.'
assert_contains "$contracts" '`critical`'
assert_contains "$contracts" '`high`'
assert_contains "$contracts" '`normal`'
assert_contains "$contracts" '`low`'
assert_contains "$contracts" 'not a merge gate'
assert_contains "$contracts" '`impact:normal`'

assert_matches 'feat/55-pr-delivery-contracts' \
  '^(feat|fix|chore|refactor)/[0-9]+-[a-z0-9]+(-[a-z0-9]+)*$'
assert_matches 'feat/pr-delivery-contracts' \
  '^(feat|fix|chore|refactor)/[a-z0-9]+(-[a-z0-9]+)*$'
assert_not_matches 'feat/55-pr-delivery-contracts-1/4' \
  '^(feat|fix|chore|refactor)/[0-9]+-[a-z0-9]+(-[a-z0-9]+)*$'
assert_matches '[pr-delivery-contracts 1/4] define contracts' \
  '^\[[a-z0-9]+(-[a-z0-9]+)* [0-9]+/[0-9]+\] .+$'

for impact in critical high normal low; do
  assert_matches "impact:$impact" '^impact:(critical|high|normal|low)$'
done

assert_contains "$commit_guidance" 'must not contain forge-specific issue-closing metadata'
if grep -Eiq '\b(Fixes|Resolves|Closes|Refs|Related to):? #[0-9]+\b|![0-9]+\b' "$commit_guidance"; then
  printf 'contracts: concrete forge issue metadata found in %s\n' "$commit_guidance" >&2
  exit 1
fi

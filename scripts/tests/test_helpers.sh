#!/usr/bin/env bash

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
makefile="$repo_root/Makefile"
readme="$repo_root/README.md"
context="$repo_root/docs/CONTEXT.md"
test_runner="$repo_root/scripts/test.sh"
commit_skill="$repo_root/skills/engineering/commit/SKILL.md"
conventional_commits_skill="$repo_root/skills/engineering/conventional-commits/SKILL.md"
handoff_skill="$repo_root/skills/productivity/handoff/SKILL.md"
to_spec_skill="$repo_root/skills/engineering/to-spec/SKILL.md"
to_tickets_skill="$repo_root/skills/engineering/to-tickets/SKILL.md"
wayfinder_skill="$repo_root/skills/engineering/wayfinder/SKILL.md"
grill_with_docs_skill="$repo_root/skills/engineering/grill-with-docs/SKILL.md"
issue_hierarchy="$repo_root/skills/shared/issue-hierarchy.md"
capture_skill="$repo_root/skills/engineering/capture/SKILL.md"
implement_skill="$repo_root/skills/engineering/implement/SKILL.md"
implement_skill_work="$repo_root/skills/engineering/implement-skill/SKILL.md"
improve_skill="$repo_root/skills/engineering/improve-skill/SKILL.md"
review_skill="$repo_root/skills/engineering/review-skill/SKILL.md"
code_review_skill="$repo_root/skills/engineering/code-review/SKILL.md"
github_skill="$repo_root/skills/engineering/github/SKILL.md"
gitlab_skill="$repo_root/skills/engineering/gitlab/SKILL.md"
diagnosing_bugs_skill="$repo_root/skills/engineering/diagnosing-bugs/SKILL.md"
triage_skill="$repo_root/skills/engineering/triage/SKILL.md"
research_skill="$repo_root/skills/engineering/research/SKILL.md"
merge_conflicts_skill="$repo_root/skills/engineering/resolving-merge-conflicts/SKILL.md"
prototype_skill="$repo_root/skills/engineering/prototype/SKILL.md"
prototype_logic="$repo_root/skills/engineering/prototype/LOGIC.md"
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

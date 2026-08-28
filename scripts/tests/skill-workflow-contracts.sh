#!/usr/bin/env bash
set -euo pipefail

TEST_CONCERN=skill-workflow
# shellcheck source=test_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/test_helpers.sh"

assert_file "$implement_skill"
assert_file "$capture_skill"
assert_file "$implement_skill_work"
assert_file "$improve_skill"
assert_file "$review_skill"
assert_file "$code_review_skill"
assert_file "$diagnosing_bugs_skill"
assert_file "$triage_skill"
assert_file "$research_skill"
assert_file "$merge_conflicts_skill"
assert_file "$prototype_skill"
assert_file "$prototype_logic"
assert_file "$commit_skill"
assert_file "$pr_skill"
assert_file "$conventional_commits_skill"
assert_file "$handoff_skill"
assert_file "$to_spec_skill"
assert_file "$to_tickets_skill"
assert_file "$wayfinder_skill"
assert_file "$grill_with_docs_skill"
assert_file "$issue_hierarchy"
assert_file "$continuation"
assert_file "$subagent_dispatch"

assert_contains_many_normalized "$continuation" \
  'Current state' \
  '`ready` means at least one action can start now.' \
  '`blocked` means a dependency prevents every action' \
  'dependency is' \
  'issue or task' \
  '`pending` means the workflow is waiting for a human or external result' \
  'including when that result is' \
  'listed as a dependency' \
  '`complete` means its declared result is achieved.' \
  'Ready now' \
  'Later' \
  'Dependencies' \
  'Deliberate stop' \
  'multiple independent next actions' \
  'separate ready-now or later entries' \
  'owner or responsible party' \
  'expected result' \
  'dependency condition' \
  'later work must not delay' \
  'one actionable result now and non-blocking later work' \
  'One-ticket shortcut' \
  'Multi-ticket route' \
  'exactly one implementation ticket.' \
  'when implementation needs multiple tickets or a' \
  'richer requirements artifact' \
  'settled implementation landscape' \
  'Use the shortest route that preserves the required issue record' \
  'destination skills own their publication' \
  'Route to `/to-tickets`' \
  'route to `/to-spec`' \
  'Then expose `/implement`' \
  'issue record exists before' \
  'Every field is present even when it has no entries.' \
  'Use `None` for an empty' \
  'ready-now list, later list' \
  'dependency list, or deliberate stop' \
  'Classify a human or external wait as `pending`, not `blocked`.' \
  'exact continuation set belongs in the agent interaction' \
  'does not belong in an issue body or comment' \
  'Developer-facing issue records' \
  'metadata such as' \
  'Specialist-result boundary' \
  'identify the **owner**' \
  'useful result on that owner' \
  'return the owner'
assert_order_normalized "$continuation" \
  'One-ticket shortcut' \
  'exactly one implementation ticket' \
  'Route to `/to-tickets`' \
  'Then expose `/implement`'
assert_order_normalized "$continuation" \
  'Multi-ticket route' \
  'route to `/to-spec`' \
  'specification, then `/to-tickets`' \
  '`/implement` for those tickets'
assert_contains_many_normalized "$context" \
  'read [`continuation`](../skills/shared/continuation.md)' \
  'bounded one-ticket or multi-ticket branch' \
  'map, spec-ready, or follow-up-map branch' \
  'classification or deliberate-stop branch' \
  'publication or planning boundary' \
  'specialist-result boundary' \
  'commit/implementation boundary'
assert_contains_normalized "$context" 'commit/implementation boundary, read [`continuation`](../skills/shared/continuation.md)'

assert_contains_many_normalized "$commit_skill" \
  'message-only mode' \
  'It never stages or commits in this mode.' \
  'isolate each accepted group' \
  'delegated skill owns presentation and approval' \
  'amend-reword mode' \
  'git push -u origin HEAD' \
  'Do not delegate pushing back' \
  'requested footer such as `Closes #N`' \
  'Completion criterion: every staged file is agent-touched, generated, or has an explicit user decision.'

assert_contains_many_normalized "$pr_skill" \
  'name: pr' \
  'disable-model-invocation: true' \
  'Prepare one non-default implementation branch for one ticket' \
  'Identify the repository default branch' \
  'If the current branch is the default branch, stop before implementation' \
  'actionable guidance to create or switch to a non-default implementation branch' \
  'Invoke `/implement` for the identified work in PR-workflow handoff mode.' \
  '`/implement` owns issue reading, implementation, validation, review and repair' \
  'After a successful implementation handoff, invoke `/commit`.' \
  'The commit skill owns staging, safety, quality, documentation, message approval, commit creation, and pushing.' \
  '## 5. Publish one review record' \
  '### GitHub pull request' \
  '### GitLab merge request' \
  'ticket-focused body' \
  'Stack position' \
  'Dependency context' \
  'Related: #N' \
  'provider-neutral `find` operation' \
  'record: null' \
  'one `create` operation' \
  'normalized publication result' \
  'publication_failure' \
  'Preserve the pushed branch and open issue' \
  '## 6. Return the implementation-ready boundary' \
  'implementation-ready' \
  'Keep the ticket open' \
  'complete continuation set'
assert_order_normalized "$pr_skill" \
  'Identify the repository default branch' \
  'If the current branch is the default branch, stop before implementation' \
  '## 2. Prepare the implementation branch' \
  'Verify the current branch is non-default immediately before the implementation handoff' \
  '## 3. Delegate implementation' \
  'Invoke `/implement`' \
  '## 4. Delegate commit and push' \
  'invoke `/commit`' \
  '## 5. Publish one review record' \
  'provider-neutral `find` operation' \
  'one `create` operation' \
  '## 6. Return the implementation-ready boundary'
assert_not_contains "$pr_skill" 'git commit'
assert_not_contains "$pr_skill" 'git push'
assert_contains_many_normalized "$implement_skill" \
  'When `/implement` was invoked by `/pr` in PR-workflow handoff mode' \
  'return after step 3' \
  'The ordinary route below is unchanged when `/implement` is invoked directly.'
assert_order_normalized "$implement_skill" \
  'return after step 3' \
  'Create a single commit through `/commit`' \
  'Verify closure' \
  '## 5. Parent check'
assert_order_normalized "$commit_skill" \
  '## 6. Commit' \
  'Report the commit hash.' \
  '## 7. Push' \
  'git push -u origin HEAD'
assert_contains_many_normalized "$conventional_commits_skill" \
  'message-only mode' \
  'return the approved message(s)' \
  'return the approved message(s) and accepted split' \
  'Do not run `git add`, `git commit`' \
  'git push' \
  'route to `/commit` before' \
  'starting these steps' \
  'including a request for a conventional commit' \
  'draft-only mode' \
  'existing commit and diff instead' \
  'Direct commit requests route through /commit.' \
  'all applicable checks pass'
assert_not_contains "$conventional_commits_skill" 'Run `git commit -m'
assert_not_contains "$conventional_commits_skill" 'Run `git push -u origin HEAD'

assert_contains_many_normalized "$handoff_skill" \
  'agent-handoff-XXXXXX.md' \
  'secure temporary-file API' \
  'absolute path' \
  'Completion criterion'
assert_contains_many_normalized "$diagnosing_bugs_skill" \
  '## Redact' \
  '<REDACTED>' \
  'redacted captured artifact'
assert_contains "$diagnosing_bugs_skill" '## Redact'
assert_contains_many_normalized "$triage_skill" \
  'external pull requests' \
  'This was generated by AI during triage.' \
  'for a PR, read the diff too' \
  'tag each line `[PR]` or `[issue]`' \
  'prepend the exact disclaimer above' \
  'Do not infer external-PR scope from repository activity alone.'
assert_contains_many_normalized "$grilling_skill" \
  'shared [`continuation`](../../shared/continuation.md)' \
  'One-ticket' \
  'exactly one implementation ticket remains' \
  'Multi-ticket' \
  'Too large' \
  'uncharted Wayfinder map' \
  'Return the complete continuation set'
assert_order_normalized "$grilling_skill" \
  'One-ticket' \
  '`/to-tickets`' \
  '`/implement` later' \
  'Multi-ticket' \
  '`/to-spec`' \
  'Too large' \
  'uncharted Wayfinder map'
assert_contains_many_normalized "$grill_with_docs_skill" \
  'One-ticket' \
  'Multi-ticket' \
  'Too large' \
  'uncharted Wayfinder map' \
  'complete continuation set' \
  'The too-large branch is a map continuation'
assert_contains_many_normalized "$triage_skill" \
  '`kind:spec` only for a published specification' \
  'Clarification needed' \
  'Bounded ticket' \
  'Published spec' \
  'Human-owned' \
  'Rejected' \
  'Already implemented' \
  'Do not apply `kind:spec`'
assert_contains_many_normalized "$wayfinder_skill" \
  'shared [`continuation`](../../shared/continuation.md)' \
  'Uncharted map' \
  'Charted map' \
  'Spec-ready' \
  'One-ticket shortcut' \
  'Decision captured' \
  'Follow-up map' \
  'exactly one implementation ticket remains' \
  'Wayfinder never places `/implement` in the ready-now route'
assert_contains_many_normalized "$prototype_skill" \
  'single shareable HTML demo' \
  'LOGIC.md' \
  'A UI prototype starts from one command' \
  'A logic prototype is a self-contained HTML file' \
  'requesting owner' \
  'Capture and clean up when done' \
  'project-local prototype file, route, and switcher' \
  'Return the owner'
assert_contains_many_normalized "$prototype_logic" \
  'single, self-contained HTML file' \
  'Completion: the demo states the question' \
  'Completion: the logic is isolated' \
  'Completion: the file opens without installation' \
  'developer-facing owner record' \
  'no prototype residue remains'
assert_contains_many_normalized "$prototype_ui" \
  'developer-facing owner record' \
  'Remove every losing variant' \
  'project-local prototype residue is removed' \
  'Continue the owner'
assert_order "$prototype_logic" \
  '### 1. State the question' \
  '### 2. Isolate the logic' \
  '### 3. Build the shareable HTML file' \
  '### 4. Hand it over' \
  '### 5. Capture the answer and clean up'
assert_contains_many_normalized "$research_skill" \
  'primary sources' \
  'researcher' \
  'must not invoke `research` recursively' \
  'return structured findings' \
  'stable per-user XDG cache' \
  '${XDG_CACHE_HOME:-$HOME/.cache}/skills/research/<topic-slug>.md' \
  'OS temp is scratch only' \
  'issue-backed owner record' \
  'owner continuation'
assert_not_contains "$research_skill" 'docs/research/<topic-slug>.md'
assert_contains_many_normalized "$subagent_dispatch" \
  'canonical record to the stable per-user XDG cache' \
  'scratch notes stay in OS temp'
assert_not_contains "$subagent_dispatch" 'docs/research/<topic-slug>.md'
assert_contains_many_normalized "$diagnosing_bugs_skill" \
  'Identify the owner' \
  'owner receives the redacted' \
  'developer-facing owner record' \
  "owner's complete continuation set"
assert_contains_many_normalized "$merge_conflicts_skill" \
  'primary sources' \
  'Do not use `git merge --abort` or `git rebase --abort`' \
  'command-runner' \
  'Route the merge or rebase commit through `/commit`'

assert_contains_many_normalized "$issue_hierarchy" \
  'GitHub' \
  'GitLab' \
  'issue_type=task' \
  'Blocking is separate from parentage.'
assert_contains_many_normalized "$gitlab_skill" \
  'issue_type=task' \
  '/set_parent' \
  'parentIds: [$parentId]' \
  'types: [TASK]' \
  'pageInfo { hasNextPage endCursor }' \
  'features { assignees'

assert_contains_many_normalized "$to_spec_skill" \
  '`kind:decision`' \
  'type:bug' \
  'otherwise use `type:enhancement`' \
  'child tickets through the matching' \
  'If the map is open' \
  'Do not apply `kind:spec` until the specification has been published successfully.' \
  'one issue record' \
  'body limit' \
  'ordered comments' \
  '## Spec overflow N/M' \
  'human-readable line' \
  'not a parent-child relationship' \
  'published `kind:spec` issue is ready now for `/to-tickets`'
assert_order_normalized "$to_spec_skill" \
  'fit complete sections' \
  'body limit' \
  'ordered comments' \
  'Publish to the issue tracker with labels' \
  'human-readable line' \
  'published `kind:spec` issue is ready now for `/to-tickets`'
assert_not_contains "$to_spec_skill" 'Check with the user that these seams match their expectations.'
assert_contains_many_normalized "$to_tickets_skill" \
  'child tasks' \
  'full spec source' \
  'issue body first, then append comments' \
  '## Spec overflow N/M' \
  'Overflow comments are part of the specification' \
  'Do not stamp `kind:spec` from this planning workflow.' \
  'native parent/child hierarchy' \
  'exactly one implementation ticket' \
  'create that one native child issue first' \
  'issue records and their edges exist'
assert_order_normalized "$to_tickets_skill" \
  'assemble the full spec source' \
  'issue body first' \
  'Overflow comments are part of the specification' \
  'native child tickets' \
  'exactly one implementation ticket' \
  'create that one native child issue first'
assert_contains "$wayfinder_skill" 'child task work items'
assert_contains_many_normalized "$implement_skill" \
  'Create a single commit through `/commit`' \
  '`/commit` owns staging, safety, quality and documentation gates, message approval, local commit creation, and push.'
assert_not_contains "$implement_skill" 'Push: `git push -u origin HEAD`'
assert_contains "$wayfinder_skill" 'Run `/commit`'
assert_contains "$grill_with_docs_skill" 'run `/commit`'
assert_not_contains "$implement_skill" 'conventional-commits'
assert_contains_many_normalized "$merge_conflicts_skill" \
  'the gate owns commit creation and pushing' \
  'Do not run `git commit` or `git push` directly.'

assert_contains_many_normalized "$implement_skill_work" \
  'name: implement-skill' \
  'disable-model-invocation: true' \
  'writing-for-agents' \
  'command-runner.md' \
  '## 1. Establish the contract' \
  '## 4. Establish green before review' \
  "Run the project's \`check\` target and then its \`test\` target" \
  'Both must pass before any' \
  'review only a green worktree' \
  'If no command runner is configured' \
  'record the limitation' \
  'stop before' \
  'review rather than claiming a green worktree' \
  'and no review' \
  'claimed' \
  '## 5. Review and repair' \
  "A substantial change alters a skill's process" \
  'A wording-only or' \
  'invoke `/review-skill` once against the fixed point' \
  'Standards, Spec, and Coverage' \
  'fresh review context' \
  'targeted checks' \
  'wording-only or test-only corrections' \
  'materially changes behavior, scope, or invocation mechanics' \
  'pass the green gate again before the rerun' \
  '## 6. Final verification' \
  "After all review repairs and any justified review rerun, run the project's" \
  'final full checks are mandatory' \
  'freshness boundary' \
  'independent staged-diff quality gate' \
  'Report the changed skill paths' \
  'invocation decision' \
  'verification commands and outcomes' \
  'unresolved limitation'
assert_contains_many "$implement_skill_work" \
  'name: implement-skill' \
  'disable-model-invocation: true' \
  '## 1. Establish the contract' \
  '## 4. Establish green before review' \
  '## 5. Review and repair' \
  '## 6. Final verification' \
  '## 7. Report the result'
assert_order_normalized "$implement_skill_work" \
  '## 3. Implement the change' \
  '## 4. Establish green before review' \
  "Run the project's \`check\` target and then its \`test\` target" \
  'review starts' \
  'If either target fails, repair the implementation and repeat this gate' \
  '## 5. Review and repair' \
  'For a substantial change, invoke' \
  'After a repair, classify its impact' \
  'targeted checks' \
  'Repeat the full three-axis review only when' \
  'For that material repair, pass the green gate again' \
  '## 6. Final verification' \
  'After all review repairs' \
  "run the project's \`check\` target and then its \`test\` target" \
  '## 7. Report the result'

order_fixture="$(mktemp)"
trap 'rm -f "$order_fixture"' EXIT
printf 'first\nsecond\n    item\nthird\n' > "$order_fixture"
assert_contains_normalized "$order_fixture" 'second item'
if (assert_contains_normalized "$order_fixture" 'missing') 2>/dev/null; then
  fail 'normalized containment helper accepted a missing marker'
fi
assert_order_normalized "$order_fixture" 'first' 'second item' 'third'
if (assert_order_normalized "$order_fixture" 'missing') 2>/dev/null; then
  fail 'normalized order helper accepted a missing marker'
fi
if (assert_order_normalized "$order_fixture" 'third' 'first') 2>/dev/null; then
  fail 'normalized order helper accepted reversed markers'
fi

assert_contains_many_normalized "$capture_skill" \
  'All forge calls follow the recipes' \
  'matching forge skill' \
  'does not run forge commands directly'
assert_not_contains "$capture_skill" 'gh issue create'
assert_not_contains "$capture_skill" 'gh label create'
assert_not_contains "$capture_skill" 'glab issue create'
assert_not_contains "$capture_skill" 'glab label create'

assert_contains_many_normalized "$improve_skill" \
  'name: improve-skill' \
  'disable-model-invocation: true' \
  'writing-for-agents' \
  'command-runner.md' \
  'If the user names no skill, run a portfolio scan:' \
  'Inventory every skill directory under `skills/`' \
  'Run the lightweight audits in parallel' \
  'Do not edit during the scan.' \
  '## 2. Explore the skill' \
  '## 3. Present candidates' \
  'Do not edit until the user picks a candidate.'
assert_contains_many "$improve_skill" \
  'name: improve-skill' \
  'disable-model-invocation: true' \
  '## 2. Explore the skill' \
  '## 3. Present candidates'

assert_contains_many_normalized "$review_skill" \
  'name: review-skill' \
  'command-runner.md' \
  'review checkpoint, not a debugging loop' \
  'The caller owns repairs after the checkpoint' \
  'Capture the diff, commit list, and worktree status once' \
  'The caller should run the project' \
  'supply both results with the review packet' \
  'worktree changed since the captured snapshot' \
  'run the shared targets once in sequence (`check`, then `test`) before spawning review agents' \
  'When this fallback gate runs, run the repository targets once for the checkpoint, not once per axis' \
  'consume the captured check results' \
  'do not independently rerun the full repository suite' \
  'same captured diff, source material, and check/test results' \
  'Standards' \
  'Spec' \
  'Coverage' \
  'Use fresh parallel review agents' \
  'Findings come first so the caller can choose repairs' \
  'Minor caller repairs use targeted checks' \
  'Rerun all three axes only after a repair materially changes behavior, scope, or invocation mechanics' \
  'same fixed point and repeats the green precondition first' \
  'does not edit the skill' \
  'internal owner' \
  'developer-facing owner record' \
  "owner's complete continuation set"
assert_contains_many "$review_skill" \
  'name: review-skill'
assert_contains_many "$review_skill" \
  '## 1. Pin the review' \
  '## 2. Identify the sources' \
  '## 3. Establish green before review' \
  '## 4. Run the three axes in parallel' \
  '## 5. Aggregate findings'

assert_contains "$code_review_skill" 'command-runner.md'
assert_not_contains "$code_review_skill" 'make lint'
assert_not_contains "$code_review_skill" 'make fmt'
assert_not_contains "$code_review_skill" 'make check'

for skill in "$implement_skill_work" "$improve_skill" "$review_skill"; do
  assert_not_contains "$skill" 'make check'
  assert_not_contains "$skill" 'make test'
done

assert_contains_many_normalized "$implement_skill" \
  'Treat the issue body as the canonical source for body checkboxes.' \
  'Update the original issue body in place' \
  'preserving all unrelated text and replacing only satisfied' \
  'Record each criterion only in its source container.' \
  'edit the original comment in place via the forge skill' \
  'comment-edit recipe' \
  'body criteria remain in the issue body' \
  'every satisfied comment-only criterion is checked in its source comment' \
  'Automatic selection includes only open issues labeled `triage:for-agent`.' \
  'Exclude `triage:pending`, `triage:unanswered`, unlabeled, `triage:for-human`, and `triage:wontfix` issues.' \
  'Query open `triage:pending` issues separately and report them in a `requires triage` section.' \
  'If none, use the assigned-to-@me fallback, still requiring `triage:for-agent` and no open blockers.' \
  'If no eligible issue remains, report that no implementation-ready issue exists and stop without claiming one.' \
  "Use the matching forge's blocker relationship from the shared hierarchy contract." \
  'A ticket is unblocked only when every blocker is closed;' \
  'inspect each blocker state, while any open blocker excludes the candidate.'

assert_not_contains "$implement_skill" 'Unassigned and unblocked — sort by priority then age.'
assert_not_contains "$implement_skill" 'If none, assigned to @me and unblocked.'

assert_unblocked_by_state() {
  local blockers="$1"
  local expected="$2"
  local actual
  actual="$(jq -r 'all(.[]; .state == "CLOSED")' <<< "$blockers")"
  [ "$actual" = "$expected" ] || fail "blocker state resolved to $actual, expected $expected"
}

assert_unblocked_by_state '[{"state":"CLOSED"},{"state":"CLOSED"}]' true
assert_unblocked_by_state '[{"state":"CLOSED"},{"state":"OPEN"}]' false

assert_contains_many_normalized "$code_review_skill" \
  'Three-axis review of the diff' \
  'Standards' \
  'Spec' \
  'Coverage' \
  'All three axes run as **parallel sub-agents**' \
  'internal owner' \
  'developer-facing owner record' \
  "owner's complete continuation set"

# Integration fixtures exercise the boundary contracts, rather than only
# checking that each route's vocabulary appears somewhere in its skill.
bounded_fixture="$(mktemp)"
multi_ticket_fixture="$(mktemp)"
map_fixture="$(mktemp)"
overflow_fixture="$(mktemp -d)"
specialist_fixture="$(mktemp)"
public_fixture="$(mktemp)"
commit_fixture="$(mktemp)"
pr_default_fixture="$(mktemp)"
pr_feature_fixture="$(mktemp)"
pr_ordinary_fixture="$(mktemp)"
trap 'rm -f "$order_fixture" "$bounded_fixture" "$multi_ticket_fixture" "$map_fixture" "$specialist_fixture" "$public_fixture" "$commit_fixture" "$pr_default_fixture" "$pr_feature_fixture" "$pr_ordinary_fixture"; rm -rf "$overflow_fixture"' EXIT

printf '%s\n' \
  'Default branch: main' \
  'Current branch: main' \
  'Result: stop before /implement' \
  'Guidance: create or switch to a non-default implementation branch' \
  'Implementation: not started' > "$pr_default_fixture"
assert_order_normalized "$pr_default_fixture" \
  'Default branch: main' \
  'Current branch: main' \
  'Result: stop before /implement' \
  'Guidance: create or switch to a non-default implementation branch' \
  'Implementation: not started'

printf '%s\n' \
  'Default branch: main' \
  'Current branch: feature/ticket' \
  'Selected branch: feature/ticket' \
  'Implementation handoff: /implement' \
  'Commit handoff: /commit' \
  'Result: pushed branch ready for PR publication' > "$pr_feature_fixture"
assert_order_normalized "$pr_feature_fixture" \
  'Default branch: main' \
  'Current branch: feature/ticket' \
  'Selected branch: feature/ticket' \
  'Implementation handoff: /implement' \
  'Commit handoff: /commit' \
  'Result: pushed branch ready for PR publication'

assert_file "$pr_workflow_fixture"
assert_file "$pr_failure_fixture"
workflow_events="$(jq -c '[.events[] | {stage,delegation,operation}]' "$pr_workflow_fixture")"
expected_workflow_events='[{"stage":"branch","delegation":null,"operation":null},{"stage":"implement","delegation":"/implement","operation":null},{"stage":"commit","delegation":"/commit","operation":null},{"stage":"forge","delegation":null,"operation":"find"},{"stage":"forge","delegation":null,"operation":"create"},{"stage":"workflow","delegation":null,"operation":null}]'
[ "$workflow_events" = "$expected_workflow_events" ] ||
  fail "single-ticket workflow changed order: $workflow_events"
[ "$(jq -r '.events[2].commits' "$pr_workflow_fixture")" = 1 ] ||
  fail 'single-ticket workflow did not prove one commit'
[ "$(jq -r '.events[2].pushed' "$pr_workflow_fixture")" = true ] ||
  fail 'single-ticket workflow did not prove push'
[ "$(jq -r '.events[0].branch' "$pr_workflow_fixture")" = "$(jq -r '.source_branch' "$pr_workflow_fixture")" ] ||
  fail 'single-ticket workflow did not preserve the selected source branch'
[ "$(jq -r '.default_branch' "$pr_workflow_fixture")" = main ] ||
  fail 'single-ticket workflow did not preserve the default target branch'
[ "$(jq -r '.events[3].skill' "$pr_workflow_fixture")" = github ] ||
  fail 'single-ticket workflow did not hand publication to GitHub'
[ "$(jq -r '.events[4].records' "$pr_workflow_fixture")" = 1 ] ||
  fail 'single-ticket workflow did not prove one GitHub pull request'
[ "$(jq -r '.events[4].source_branch' "$pr_workflow_fixture")" = "$(jq -r '.source_branch' "$pr_workflow_fixture")" ] ||
  fail 'single-ticket publication changed the source branch'
[ "$(jq -r '.events[4].target_branch' "$pr_workflow_fixture")" = "$(jq -r '.default_branch' "$pr_workflow_fixture")" ] ||
  fail 'single-ticket publication changed the target branch'
[ "$(jq -r '.events[5].implementation_ready' "$pr_workflow_fixture")" = true ] ||
  fail 'single-ticket workflow did not prove implementation-ready state'
[ "$(jq -r '.issue_state' "$pr_workflow_fixture")" = open ] ||
  fail 'single-ticket workflow changed the issue state'
for field in change_scope notable_decisions validation dependency_context; do
  jq -e --arg field "$field" '.body[$field] != null and (.body[$field] | length) > 0' "$pr_workflow_fixture" >/dev/null ||
    fail "single-ticket body is missing $field content"
done
[ "$(jq -r '.body.acceptance_results' "$pr_workflow_fixture")" = 7 ] ||
  fail 'single-ticket body did not mirror all ticket criteria'
for section in 'Change scope' 'Notable decisions' 'Validation' 'Acceptance results' \
  'Spec context' 'Stack position' 'Dependency context' 'Related records'; do
  jq -e --arg section "$section" '.body.sections | index($section) != null' "$pr_workflow_fixture" >/dev/null ||
    fail "single-ticket body is missing $section"
done
[ "$(jq -r '.body.reference' "$pr_workflow_fixture")" = 'Related: #90' ] ||
  fail 'single-ticket body lost its non-closing ticket reference'
[ "$(jq -r '.body.closing_reference' "$pr_workflow_fixture")" = false ] ||
  fail 'single-ticket body has a closing reference'
for field in record_id url title body source_branch target_branch head_sha state; do
  jq -e --arg field "$field" '.publication[$field] != null and (.publication[$field] | length) > 0' "$pr_workflow_fixture" >/dev/null ||
    fail "single-ticket publication is missing $field"
done
[ "$(jq -r '.publication.state' "$pr_workflow_fixture")" = open ] ||
  fail 'single-ticket publication is not reviewable'
[ "$(jq -r '.publication.source_branch' "$pr_workflow_fixture")" = "$(jq -r '.source_branch' "$pr_workflow_fixture")" ] ||
  fail 'single-ticket normalized result changed the source branch'
[ "$(jq -r '.publication.target_branch' "$pr_workflow_fixture")" = "$(jq -r '.default_branch' "$pr_workflow_fixture")" ] ||
  fail 'single-ticket normalized result changed the target branch'
[ "$(jq -r '.publication.head_sha' "$pr_workflow_fixture")" = "$(jq -r '.events[2].head_sha' "$pr_workflow_fixture")" ] ||
  fail 'single-ticket normalized result changed the pushed head'
for state in implementation-ready merged closed; do
  jq -e --arg state "$state" '.lifecycle[] | select(.name == $state)' "$pr_workflow_fixture" >/dev/null ||
    fail "single-ticket lifecycle is missing $state"
done
[ "$(jq -r '.lifecycle[0].issue_state' "$pr_workflow_fixture")" = open ] ||
  fail 'implementation-ready did not preserve the open issue'
[ "$(jq -r '.lifecycle[0].publication_state' "$pr_workflow_fixture")" = open ] ||
  fail 'implementation-ready did not preserve the open publication'
[ "$(jq -r '.lifecycle[1].publication_state' "$pr_workflow_fixture")" = merged ] ||
  fail 'merged state is not distinct from implementation-ready'
[ "$(jq -r '.lifecycle[2].issue_state' "$pr_workflow_fixture")" = closed ] ||
  fail 'closed state is not distinct from implementation-ready'

for class in tooling-unavailable authentication-required permission-denied publication-failed; do
  jq -e --arg class "$class" \
    '.failures[] | select(.failure_class == $class and .retryable == true and .publication_exists == false and .preserved_branch == true and .preserved_issue == true and .stop_before_claim == true and .implementation_ready == false)' \
    "$pr_failure_fixture" >/dev/null || fail "workflow failure state is incomplete for $class"
done

assert_file "$gitlab_pr_workflow_fixture"
gitlab_workflow_events="$(jq -c '[.events[] | {stage,delegation,operation}]' "$gitlab_pr_workflow_fixture")"
[ "$gitlab_workflow_events" = "$expected_workflow_events" ] ||
  fail "GitLab single-ticket workflow changed order: $gitlab_workflow_events"
[ "$(jq -r '.events[2].commits' "$gitlab_pr_workflow_fixture")" = 1 ] ||
  fail 'GitLab workflow did not prove one commit'
[ "$(jq -r '.events[2].pushed' "$gitlab_pr_workflow_fixture")" = true ] ||
  fail 'GitLab workflow did not prove push'
[ "$(jq -r '.events[3].skill' "$gitlab_pr_workflow_fixture")" = gitlab ] ||
  fail 'GitLab workflow did not hand publication to GitLab'
[ "$(jq -r '.events[4].records' "$gitlab_pr_workflow_fixture")" = 1 ] ||
  fail 'GitLab workflow did not prove one merge request'
[ "$(jq -r '.publication.state' "$gitlab_pr_workflow_fixture")" = open ] ||
  fail 'GitLab publication is not reviewable'
[ "$(jq -r '.publication.source_branch' "$gitlab_pr_workflow_fixture")" = "$(jq -r '.source_branch' "$gitlab_pr_workflow_fixture")" ] ||
  fail 'GitLab publication changed the source branch'
[ "$(jq -r '.publication.target_branch' "$gitlab_pr_workflow_fixture")" = main ] ||
  fail 'GitLab publication changed the target branch'
[ "$(jq -r '.publication.head_sha' "$gitlab_pr_workflow_fixture")" = "$(jq -r '.events[2].head_sha' "$gitlab_pr_workflow_fixture")" ] ||
  fail 'GitLab publication changed the pushed head'
[ "$(jq -r '.publication.record_id' "$gitlab_pr_workflow_fixture")" != null ] ||
  fail 'GitLab normalized publication is missing record_id'
[ "$(jq -r '.publication.url' "$gitlab_pr_workflow_fixture")" != null ] ||
  fail 'GitLab normalized publication is missing url'
[ "$(jq -r '.publication.title' "$gitlab_pr_workflow_fixture")" != null ] ||
  fail 'GitLab normalized publication is missing title'
[ "$(jq -r '.publication.body' "$gitlab_pr_workflow_fixture")" != null ] ||
  fail 'GitLab normalized publication is missing body'
for field in change_scope notable_decisions validation dependency_context; do
  jq -e --arg field "$field" ".body[\$field] != null and (.body[\$field] | length) > 0" \
    "$gitlab_pr_workflow_fixture" >/dev/null ||
    fail "GitLab body is missing $field content"
done
for section in 'Change scope' 'Notable decisions' 'Validation' 'Acceptance results' \
  'Spec context' 'Stack position' 'Dependency context' 'Related records'; do
  jq -e --arg section "$section" '.body.sections | index($section) != null' \
    "$gitlab_pr_workflow_fixture" >/dev/null ||
    fail "GitLab body is missing $section"
done
[ "$(jq -r '.body.reference' "$gitlab_pr_workflow_fixture")" = 'Related: #91' ] ||
  fail 'GitLab body lost its non-closing ticket reference'
[ "$(jq -r '.body.closing_reference' "$gitlab_pr_workflow_fixture")" = false ] ||
  fail 'GitLab body has a closing reference'
[ "$(jq -r '.body.acceptance_results' "$gitlab_pr_workflow_fixture")" = 7 ] ||
  fail 'GitLab body did not mirror all ticket criteria'
for state in implementation-ready merged closed; do
  jq -e --arg state "$state" '.lifecycle[] | select(.name == $state)' \
    "$gitlab_pr_workflow_fixture" >/dev/null ||
    fail "GitLab lifecycle is missing $state"
done
[ "$(jq -r '.lifecycle[0].issue_state' "$gitlab_pr_workflow_fixture")" = open ] ||
  fail 'GitLab implementation-ready state closed the issue'
[ "$(jq -r '.lifecycle[1].publication_state' "$gitlab_pr_workflow_fixture")" = merged ] ||
  fail 'GitLab merged state is not distinct from implementation-ready'
[ "$(jq -r '.lifecycle[2].issue_state' "$gitlab_pr_workflow_fixture")" = closed ] ||
  fail 'GitLab closed state is not distinct from implementation-ready'

printf '%s\n' \
  'Direct invocation: /implement' \
  'Implementation and validation' \
  'Review and repair' \
  'Acceptance handling' \
  'Commit and push through /commit' \
  'Issue closure' \
  'Parent check' > "$pr_ordinary_fixture"
assert_order_normalized "$pr_ordinary_fixture" \
  'Direct invocation: /implement' \
  'Implementation and validation' \
  'Review and repair' \
  'Acceptance handling' \
  'Commit and push through /commit' \
  'Issue closure' \
  'Parent check'

printf '%s\n' \
  'Current state: ready' \
  'Ready now: /to-tickets creates exactly one implementation issue record' \
  'Later: /implement after the issue record exists' \
  'Dependencies: None' \
  'Deliberate stop: None' > "$bounded_fixture"
assert_order_normalized "$bounded_fixture" \
  'Current state: ready' \
  'Ready now: /to-tickets' \
  'Later: /implement after the issue record exists'
assert_not_contains "$bounded_fixture" 'Ready now: /to-spec'

printf '%s\n' \
  'Current state: ready' \
  'Ready now: /to-spec publishes one specification' \
  'Later: /to-tickets after publication; /implement after issue records exist' \
  'Dependencies: None' \
  'Deliberate stop: None' > "$multi_ticket_fixture"
assert_order_normalized "$multi_ticket_fixture" \
  'Ready now: /to-spec' \
  'Later: /to-tickets after publication' \
  '/implement after issue records exist'
assert_not_contains "$multi_ticket_fixture" 'Ready now: /implement'

printf '%s\n' \
  'Current state: ready' \
  'Ready now: /to-spec for the actionable multi-ticket landscape' \
  'Later: create an uncharted Wayfinder map for non-blocking follow-up fog' \
  'Dependencies: None' \
  'Deliberate stop: None' > "$map_fixture"
assert_order_normalized "$map_fixture" \
  'Ready now: /to-spec' \
  'Later: create an uncharted Wayfinder map'
assert_not_contains "$map_fixture" 'Ready now: create an uncharted Wayfinder map'

printf '%s\n' \
  '## Spec body' \
  'Problem Statement' > "$overflow_fixture/body"
printf '%s\n' \
  '## Spec overflow 2/2' \
  'Testing Decisions' > "$overflow_fixture/overflow-2"
printf '%s\n' \
  '## Spec overflow 1/2' \
  'Implementation Decisions' > "$overflow_fixture/overflow-1"
overflow_source="$overflow_fixture/assembled"
{
  cat "$overflow_fixture/body"
  while IFS= read -r comment; do
    cat "$comment"
  done < <(printf '%s\n' "$overflow_fixture"/overflow-* | sort -V)
} > "$overflow_source"
assert_order "$overflow_source" \
  'Problem Statement' \
  'Implementation Decisions' \
  'Testing Decisions'
assert_contains "$overflow_source" '## Spec overflow 1/2'
assert_contains "$overflow_source" '## Spec overflow 2/2'

printf '%s\n' \
  'Owner: implementation issue' \
  'Result: cited specialist finding' \
  'Canonical record: stable XDG cache' \
  'Scratch: OS temp, removed after synthesis' \
  'Owner continuation: returned in the live interaction' > "$specialist_fixture"
assert_order_normalized "$specialist_fixture" \
  'Owner: implementation issue' \
  'Result: cited specialist finding' \
  'Canonical record: stable XDG cache' \
  'Scratch: OS temp, removed after synthesis' \
  'Owner continuation: returned in the live interaction'
assert_not_contains "$specialist_fixture" 'Canonical record: project docs'
assert_contains_many_normalized "$research_skill" \
  'owner before gathering evidence' \
  'stable per-user XDG cache' \
  'OS temp is scratch only'
assert_contains_many_normalized "$prototype_skill" \
  'owner before building' \
  'remove every project-local prototype file, route, and switcher'
artifact_fixture="$(mktemp -d)"
mkdir -p "$artifact_fixture/project" "$artifact_fixture/scratch"
printf '%s\n' 'prototype residue' > "$artifact_fixture/project/prototype.html"
printf '%s\n' 'scratch notes' > "$artifact_fixture/scratch/research.md"
rm -f "$artifact_fixture/project/prototype.html" "$artifact_fixture/scratch/research.md"
[ ! -e "$artifact_fixture/project/prototype.html" ] ||
  fail 'prototype residue survived the completion boundary'
[ ! -e "$artifact_fixture/scratch/research.md" ] ||
  fail 'scratch artifact survived the completion boundary'
rm -rf "$artifact_fixture"

awk '/^## The map body$/{capture=1; next} /^## Tickets$/{capture=0} capture' \
  "$wayfinder_skill" > "$public_fixture"
awk '/^<spec-template>$/{capture=1; next} /^<\/spec-template>$/{capture=0} capture' \
  "$to_spec_skill" >> "$public_fixture"
cat "$issue_template" >> "$public_fixture"
assert_not_contains "$public_fixture" 'Current state'
assert_not_contains "$public_fixture" 'Ready now'
assert_not_contains "$public_fixture" 'Dependencies'
assert_not_contains "$public_fixture" 'Deliberate stop'
assert_not_contains "$public_fixture" '/implement'

printf '%s\n' \
  'Commit owner: /commit' \
  'Message policy: /conventional-commits returns an approved message' \
  'Execution: /commit creates the local commit and pushes it' > "$commit_fixture"
assert_order_normalized "$commit_fixture" \
  'Commit owner: /commit' \
  'Message policy: /conventional-commits returns an approved message' \
  'Execution: /commit creates the local commit and pushes it'
assert_contains_many_normalized "$commit_skill" \
  '## 1. Stage' \
  '## 2. Safety check' \
  '## 3. Quality gate' \
  '## 4. Docs gate' \
  '## 5. Message' \
  '## 6. Commit' \
  '## 7. Push'
assert_not_contains "$conventional_commits_skill" 'Run `git commit'
assert_not_contains "$conventional_commits_skill" 'Run `git push'

# Fresh-agent pointer audit: every changed workflow with a continuation
# boundary reaches the shared contract, and old direct-route wording is gone.
assert_contains "$grilling_skill" '../../shared/continuation.md'
assert_contains "$grill_with_docs_skill" '../../shared/continuation.md'
assert_contains "$triage_skill" '../../shared/continuation.md'
assert_contains "$wayfinder_skill" '../../shared/continuation.md'
assert_contains "$to_spec_skill" '../../shared/continuation.md'
assert_contains "$to_tickets_skill" '../../shared/continuation.md'
assert_contains "$research_skill" '../../shared/continuation.md'
assert_contains "$prototype_skill" '../../shared/continuation.md'
assert_contains "$prototype_logic" '../../shared/continuation.md'
assert_contains "$prototype_ui" '../../shared/continuation.md'
assert_contains "$diagnosing_bugs_skill" '../../shared/continuation.md'
assert_contains "$code_review_skill" '../../shared/continuation.md'
assert_contains "$review_skill" '../../shared/continuation.md'
assert_not_contains "$grill_with_docs_skill" 'via `/to-spec` or `/implement`'
assert_not_contains "$grilling_skill" 'plus the next step'
assert_not_contains "$wayfinder_skill" 'docs/research/<topic-slug>.md'
assert_not_contains "$to_spec_skill" 'stamp with `kind:spec`'
assert_not_contains "$to_tickets_skill" 'stamp it with `kind:spec` now'
assert_not_contains "$implement_skill" 'Push: `git push -u origin HEAD`'

printf 'skill-workflow: ok\n'

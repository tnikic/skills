---
name: merge-conflict-repair
description: Repair stale or conflicted open PRs in an isolated worktree, rebasing only clear in-scope mechanical conflicts and escalating semantic conflicts with evidence.
---

# Merge Conflict Repair

This is a maintenance workflow for an existing open PR. It is not fresh
implementation and it does not own merge, approval, or ticket lifecycle
changes.

## Inputs

The caller supplies:

- the open PR number;
- the current head SHA returned by `get_pr`;
- the PR head branch;
- the base branch;
- the linked ticket number; and
- the ticket's explicit file or behavior scope.

Reject an invocation missing any input. Call `get_pr` before touching a
worktree and verify that the PR is open and its head SHA matches the supplied
SHA. A changed head is stale input: report it and restart with fresh PR
metadata instead of repairing an older commit.

Completion: the invocation has a verified open PR, matching head SHA, base,
head branch, linked ticket, and explicit ticket scope.

## Detect

Repair only an open PR whose branch is stale or conflicted. Use the forge
adapter's normalized PR metadata to preserve the evidence that triggered
repair, including the PR number, head SHA, base branch, and linked ticket.
Local rebase detection is authoritative for conflict state; a closed or
already-current PR is a no-op.

The repair agent does not infer scope from the branch name or from changed
files. Read the linked ticket and use its declared scope as the boundary for
conflict classification.

Completion: the PR is either a no-op or has a recorded stale/conflict trigger
and an immutable ticket scope.

## Isolate

Create a temporary directory and register cleanup before creating the worktree:

```bash
worktree="$(mktemp -d)"
trap 'git worktree remove --force "$worktree" 2>/dev/null || true; rmdir "$worktree" 2>/dev/null || true' EXIT
git worktree add --detach "$worktree" "$CURRENT_HEAD_SHA"
```

Run every repair command from this isolated worktree. The source worktree
remains untouched, and cleanup runs for success, escalation, and failure. The
source worktree remains untouched even when the rebase escalates.

Completion: the isolated worktree is registered for cleanup and contains the
supplied PR head while the source worktree is unchanged.

## Rebase

Re-read `get_pr` after isolation. If the head changed, remove the worktree,
discard the stale result, and restart from `get_pr`.

Fetch the current refs inside the isolated worktree:

```bash
git fetch origin "$BASE_BRANCH" "$HEAD_BRANCH"
```

Rebase the PR head onto the current base branch:

```bash
git rebase "origin/$BASE_BRANCH"
```

The repair uses rebase rather than merging the base into the feature branch.
Never resolve a conflict before the rebase has produced its actual unmerged
paths.

Completion: the isolated worktree has fetched the current base and either
rebased cleanly or stopped with actual unmerged paths.

## Classify

When rebase stops, capture evidence before changing files:

```bash
git diff --name-only --diff-filter=U
git status --short
git diff --unified=3 --diff-filter=U
```

Classify every unmerged path and hunk against the ticket scope. A repair is
mechanical only when all of the following hold:

- every path is inside the explicit ticket scope;
- the two text sides are identical after deleting all whitespace; and
- no behavior, ordering, API, security, or dependency decision is required.

For each text path, compare the rebase stages directly:

```bash
git show ":2:$path" > "$ours"
git show ":3:$path" > "$theirs"
diff -q <(tr -d '[:space:]' < "$ours") <(tr -d '[:space:]' < "$theirs")
```

Non-text paths, missing stages, or a failed comparison are not mechanical.

Anything semantic, ambiguous, unrelated, or scope-expanding is a human
escalation. This includes a conflict where the sides differ after
normalization, a path outside the ticket scope, a missing generator, or a
resolution that would choose behavior rather than preserve it. Record the
conflicted paths, relevant hunk summaries, ticket scope, and the reason for
escalation, then run `git rebase --abort`. Do not push a guessed resolution.

Completion: every conflict is classified as mechanically resolvable or
escalated with evidence, and no unresolved semantic decision is guessed.

## Repair

Apply only the deterministic resolver named by the ticket. Repair only clear mechanical
conflicts; all other conflicts use escalation. For identical
normalized sides, either side is equivalent, so choose `ours` for that path:

```bash
git checkout --ours -- "$path"
git add -- "$path"
```

Never use a blanket ours/theirs resolution across paths.

After each mechanical resolution:

```bash
git add -- <resolved-paths>
GIT_EDITOR=: git rebase --continue
```

Repeat classification for every rebase stop. If a later stop fails the
mechanical predicate, abort and escalate with the accumulated evidence. A
successful rebase must leave no unmerged paths and must pass `git diff --check`.

Completion: the rebased worktree has no unmerged paths and every resolution is
recorded as an in-scope mechanical choice.

## Validate

From the isolated worktree, run the repository command runner's `check` and
`test` targets. In this repository those commands are:

```bash
make check
make test
```

If either local check fails, keep the PR open, do not push, and return the
failure evidence to the human. Do not broaden conflict repair into unrelated
CI or product fixes.

When both checks pass, update only the existing PR head using the expected
remote head as the lease:

```bash
git push --force-with-lease origin HEAD:"$HEAD_BRANCH"
```

Re-run `get_pr` and retain its new head SHA. Then restart the exact-head
readiness flow: discover the required checks for the base branch, call
`status_for_head` with the new PR head SHA, and wait until every required check
passes for that exact current PR head. Optional checks remain informational.

Completion: local `check` and `test` pass, the existing branch is pushed with a
lease, and exact-head readiness has restarted on the new SHA.

## Lifecycle

Repair does not reopen, close, or reassign the linked ticket. The ticket remains open and assigned, the existing PR remains open, and no merge or
approval is performed. Do not create a second PR.

Return one of these outcomes with evidence:

- `repaired`: rebase, mechanical resolution, local checks, push, and exact-head
  readiness restart completed;
- `escalated`: a semantic, ambiguous, unrelated, or scope-expanding conflict
  stopped the repair without a push;
- `validation-failed`: local checks or exact-head readiness failed; or
- `no-op`: the PR was not stale or conflicted when inspected.

The result includes the PR number, observed head SHA, base branch, linked
ticket, changed paths, local gate results, and the readiness outcome. The
source worktree and ticket lifecycle are unchanged in every outcome.

Completion: one normalized outcome is returned with enough evidence for the
human or the next workflow stage to act without inspecting hidden local state.

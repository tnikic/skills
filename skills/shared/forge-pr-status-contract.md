# Forge PR and Status Contract

This contract is the provider-neutral seam consumed by workflow skills. The
`github` and `gitlab` skills own command syntax and provider-specific response
shapes; workflow skills consume the operations and outcomes below.

## Normalized Operations

Adapters expose these operations conceptually:

| Operation | Input | Required result |
|-----------|-------|-----------------|
| `create_pr` | title, body, base, head, labels, reviewers | PR number, URL, base branch, head branch, head SHA, state |
| `get_pr` | PR number | the same PR metadata, including the current head SHA and body |
| `list_open_prs` | repository | open PR number, URL, base branch, head branch, head SHA, and body |
| `find_pr` | open head branch | zero or one matching PR with the normalized metadata |
| `update_pr` | PR number, title, body, labels | updated PR metadata, including the current head SHA |
| `retarget_pr` | PR number, base branch | updated PR metadata with the new base branch |
| `assign_reviewer` | PR number, reviewer | updated reviewer assignment |
| `list_review_comments` | PR number, optional cursor | comment ID, discussion ID (root discussion ID, or comment ID when no thread exists), author, body, timestamp, and processed state |
| `reply` | PR number, comment or discussion ID, reply | a tracker reply without changing processed state |
| `reply_and_mark_processed` | PR number, comment or discussion ID, reply, batch ID | an authenticated workflow reply containing the audit marker |
| `discover_required_checks` | repository, base branch | required check names or `configuration-gap` |
| `status_for_head` | PR number, head SHA, required checks | one normalized status outcome and evidence |

The PR body returned by `get_pr` and `list_open_prs` is the source for the
linked ticket relationship when the workflow does not receive a ticket
explicitly. The `head SHA` returned by `get_pr` is authoritative. A status result is
usable only when its observed SHA equals the current PR head SHA.

## Normalized Status

`status_for_head` returns:

```text
outcome: pending | success | failure | cancelled | stale | timeout | configuration-gap
head_sha: <observed commit SHA>
required_checks: [<name>, ...]
evidence: <short provider-independent summary>
```

Normalize provider states as follows:

- `pending`: one or more required checks have not completed.
- `success`: every required check passed for the requested head SHA.
- `failure`: a required check failed for the requested head SHA.
- `cancelled`: a required check was cancelled for the requested head SHA.
- `stale`: the observed result belongs to an older SHA than the current PR head.
- `timeout`: the bounded wait window expired while the result was unresolved.
- `configuration-gap`: required protection is absent or cannot be discovered.

Optional checks are included as evidence but never change `success` or
`pending`. A newer PR head always invalidates an older result. A workflow may
retry deterministic, ticket-scoped failures, but the adapter only reports the
normalized outcome and evidence.

The caller must re-read `get_pr` after each status query. It may accept a
success result only when the result's observed SHA equals the current PR head
SHA. If the head changed, the caller discards the result and queries again for
the new SHA. Optional checks never change readiness; readiness uses required checks only.

For GitHub, match required branch-protection contexts and ruleset checks by
name against check-runs and combined-status contexts for the requested SHA.
Missing required results remain `pending` until the wait window expires. For
GitLab, select the newest pipeline created for the requested SHA; its required
pipeline status is the `pipeline` check. A pipeline for another SHA is
`stale`, even when it is green.

## Review Audit Marker

Every processed review batch is marked in the PR thread with:

```text
[review-analysis processed:<batch-id>]
```

The marker is part of the comment body, not an out-of-band local file. A
reply must also include `Processed comment IDs: <comment-id-list>` and identify
the processed comment IDs. Only a reply authored by the authenticated workflow
identity returned by the forge adapter can create processed state. Comments
whose own body contains an external copy of the audit marker are not audit
records or actionable review instructions. A subsequent
`list_review_comments` operation treats a comment as processed when its own
body contains the marker and its author is the authenticated workflow identity,
or when an authenticated batch reply explicitly names that comment ID. A
marker never processes unrelated comments in the same discussion.

An unresolved clarification is recorded with an authenticated workflow reply
containing:

```text
[review-analysis clarification:<batch-id>]
Clarification comment IDs: <comment-id-list>
```

This marker keeps the listed comments unprocessed while allowing the next run
to resume the same clarification session instead of starting another one.

## Consistency Fixtures

These fixtures are deliberately small contract examples. They show that a
passing provider result has the same normalized meaning regardless of forge.

### Status Matrix

| normalized outcome | GitHub evidence | GitLab evidence |
|--------------------|-----------------|-----------------|
| `pending` | queued or in-progress required check | created, pending, or running pipeline |
| `success` | every required check succeeds | newest exact-SHA pipeline succeeds |
| `failure` | a required check fails | newest exact-SHA pipeline fails |
| `cancelled` | a required check is cancelled | newest exact-SHA pipeline is cancelled |
| `stale` | result SHA differs from current head | pipeline SHA differs from current head |
| `timeout` | wait window expires unresolved | wait window expires unresolved |
| `configuration-gap` | no required branch protection or ruleset | pipeline merge check is disabled or unreadable |

### GitHub

```text
raw: check-runs for head abc123 => check=success, test=success
normalized: outcome=success head_sha=abc123 required_checks=[check,test]
```

### GitLab

```text
raw: newest pipeline for SHA abc123 => status=success, merge checks require pipeline
normalized: outcome=success head_sha=abc123 required_checks=[pipeline]
```

The provider fixtures may use different required-check names, but the
normalized outcome vocabulary and head-binding rule remain identical.

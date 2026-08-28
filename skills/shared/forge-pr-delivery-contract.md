# Forge PR Delivery Contract

This is the provider-neutral seam between the PR workflow and a forge skill.
The workflow supplies policy and consumes normalized results; the matching
forge skill owns authentication, repository targeting, provider syntax, native
stack behavior, and translation from provider responses.

## Operations

Each adapter exposes these operations conceptually. The operation names and
normalized fields are stable across GitHub pull requests and GitLab merge
requests.

| Operation | Inputs | Result |
| --- | --- | --- |
| `create` | repository, `title`, `body`, `source_branch`, `target_branch`, optional `labels` and `reviewers` | normalized publication record, or a `publication_failure` |
| `find` | `repository` and `source_branch`, optionally `target_branch` | zero or one normalized publication record; multiple matches are a failure |
| `view` | `repository` and publication record identifier | normalized publication record |
| `update` | `repository`, record identifier, and changed `title`, `body`, `labels`, or `reviewers` | updated normalized publication record |
| `retarget` | `repository`, record identifier, and `target_branch` | normalized publication record with the new target |
| `publication_failure` (publication-failure) | `repository`, operation, failure class, message, and recovery context | retryable failure with preserved local state |

## Normalized Publication Record

Successful `create`, `find`, `view`, `update`, and `retarget` results use this
shape:

```text
record_id: <provider-independent review-record identifier>
url: <review-record URL>
title: <publication title>
body: <publication body>
source_branch: <head branch>
target_branch: <base branch>
head_sha: <current head commit>
state: open | merged | closed
```

`find` returns `record: null` when no record matches. A matching record is
identified by source branch as its branch identity, not by a provider-specific
stack identifier. The
adapter includes an existing record's normalized `state`, including `merged`
or `closed`, so a rerun can reconcile lifecycle state without creating a second
record. Multiple records for one source branch are an actionable failure
because the workflow cannot safely choose one.

The publication form of `find` may limit its query to open records before a
create. Lifecycle reconciliation uses the all-state form for the same branch
identity so a merged or closed record is still reused rather than duplicated.

For stacked publication, `target_branch` is the default branch for a stack root
or the selected predecessor branch for a later layer; the adapter returns that
topology without choosing or simulating it.

## Lifecycle And Reconciliation

The workflow owns normalized-state reconciliation, sequencing, and the
implementation-ready boundary. A ticket is `implementation-ready` only after
validation has passed, the selected commit is pushed, and one normalized review
record exists with `state: open`. The issue remains open at that boundary.

Intermediate records target a stack branch and use `Related: #N` or `Refs: #N`.
Only the final record whose change reaches the default branch may use `Closes
#N` for the ticket and, when applicable, its parent spec. Closure is observed
only after that final change reaches the default branch; publication never
closes an issue early.

On a rerun, `find` by source branch is the idempotent discovery step. An
existing record is viewed and reconciled, or updated and retargeted by the
forge adapter when the planned normalized state requires it. The workflow never
creates a duplicate for a branch that already has a review record. After a
predecessor is merged, the forge adapter performs native synchronization and
returns the refreshed normalized records; the workflow then sequences the next
layer.

Human review, approval, and merge are outside this contract. The workflow may
report the resulting `open`, `merged`, and later `closed` states, but it does
not perform those human decisions.

## Publication Failure

Failure results use this shape and never claim that a review record exists:

```text
operation: create | find | view | update | retarget
failure_class: tooling-unavailable | authentication-required | permission-denied | publication-failed
retryable: true
publication_exists: false | unknown
preserved_branch: true
preserved_issue: true
message: <provider-independent explanation>
action: <next safe action>
```

`retryable: true` means that rerunning after the stated prerequisite or
transient failure is safe. It does not require an immediate blind retry. An
ambiguous create first uses `find` by source branch; a retry must reuse an
existing record instead of creating a duplicate.

The workflow reports unavailable tooling, missing authentication, insufficient
permissions, and publication failures as retryable without changing the
implementation branch or issue lifecycle. Provider skills classify their
native exit codes, HTTP responses, and error bodies into these classes; the
workflow does not inspect provider-specific errors.

## Ownership

The PR workflow owns ticket selection, branch naming, sequencing, body
rendering, related versus closing references, and implementation-ready policy.
Forge skills own provider authentication, repository targeting, command and
response syntax, native stack operations, and normalization into the records
above. The shared contract contains no `gh`, `glab`, REST path, or provider
response field.

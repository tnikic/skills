---
name: gitlab
description: Work with GitLab — issues, work-item hierarchy, merge requests, labels, projects, and issue links. Exact command recipes backed by the glab CLI. Use whenever a task queries or modifies GitLab issues, MRs, labels, projects, hierarchy, or relationships, or when another skill needs a GitLab operation.
compatibility: Requires the glab CLI (glab-cli/glab), jq, and GitLab authentication with project access.
---

# GitLab forge skill

Command recipes for every GitLab operation the pipeline needs. Run the recipe as written — the agent's thinking belongs to the result, not the syntax.

> **Status**: CLI recipes were compiled from `glab --help`; raw note operations follow the [GitLab Notes REST API](https://docs.gitlab.com/api/notes/) and were not exercised against a live GitLab instance. If a recipe fails, fall back to `glab <command> --help` or the linked API reference and fix the invocation.

## Setup and auth

```bash
glab auth status            # verify the active account
glab auth login             # authenticate if not signed in
```

Self-hosted instances: `GITLAB_HOST=https://gitlab.example.com` or `--hostname` on auth. The instance is also detected from the current git remote.

Automation requires an installed `glab`, an authenticated account or token with
the `api` scope, and Developer or greater access to the target project. The
account must be able to read the project, push the selected source branch, and
create or update merge requests. Read-only project access is not sufficient for
publication.

## Repository targeting

Set both the GitLab project and the checkout explicitly. URL-encode a
`GROUP/REPO` path as `GROUP%2FREPO` for REST calls, and verify that the checkout
remote points at the same project before using a source branch:

```bash
R=GROUP/REPO
PROJECT=GROUP%2FREPO
REPO_DIR=/path/to/repository
REMOTE=origin

glab api "projects/$PROJECT" --jq '{path_with_namespace,default_branch}'
git -C "$REPO_DIR" remote get-url "$REMOTE"
git -C "$REPO_DIR" config remote.pushDefault "$REMOTE"
```

The project metadata must resolve to `R`, and the merge request target is the
reported `default_branch` unless the workflow explicitly supplies a stack
predecessor. Every `glab mr` call below includes `-R "$R"`; every REST call
uses the encoded project path.

## Conventions

- **Always target the project explicitly**: `-R GROUP/REPO` (or `OWNER/REPO`, or a full URL). Without it, glab uses the current git remote — which is the wrong project when the task targets another one.
- **Machine-readable output**: pass the JSON output flag (`-O json` on issues, `-F json` on MRs) and read the JSON. Never parse human-readable output.
- **Structured labels**: use the taxonomy in [`label-taxonomy.md`](../../shared/label-taxonomy.md) — every label is `scope:name` with a `--color` hex from [`color-palette.md`](../../shared/color-palette.md).
- **Labels must exist before use**: `glab issue create --label X` fails if X doesn't exist. List labels as JSON first; edit an existing label's color or create a missing label. This lookup/create-or-edit sequence is idempotent.
- In the recipes, `R=GROUP/REPO` — set it once per session, then copy recipes verbatim.

## Projects

```bash
glab repo create NAME --private -R $R         # create in the current user's namespace; add -g GROUP for a group
glab repo list --mine                          # your projects; -a lists every project on the instance
glab repo delete GROUP/REPO                    # permanent, cannot be undone
```

## Labels

```bash
glab label create -n scope:name -c HEX -d "description" -R $R
```

Create every missing label from the taxonomy before the first issue references it. For an existing label, list labels as JSON, extract its `id`, and pass that ID to `glab label edit`; `-n` means `--new-name`, not the label name. Reconcile existing labels so their colors match. Verify:

```bash
glab label list -R $R -F json
glab label edit --label-id LABEL_ID --color "#HEX" -R $R
glab label delete scope:name -R $R
```

## Issues

```bash
# create — labels must already exist; --yes skips the confirmation prompt
glab issue create -R $R -t "Title" -d "body" -l scope:name -l scope:name -y

# view — comments and activity
glab issue view N -R $R --comments
glab issue view N -R $R -O json
glab api "projects/GROUP%2FREPO/issues/N/notes?activity_filter=only_comments" --paginate

# list — state filters; combine with --search, --label, --not-label, --assignee
glab issue list -R $R -O json
glab issue list -R $R --closed -O json
glab issue list -R $R -l scope:name -O json
glab issue list -R $R --not-label triage:for-agent -O json
glab issue list -R $R --all --not-assignee login --order created_at --sort asc -O json   # frontier: open, unclaimed, oldest first

# comment
glab issue note N -R $R -m "text"

# edit an issue note — read it, change only satisfied markers, then send the complete body
glab api -X PUT "projects/GROUP%2FREPO/issues/N/notes/COMMENT_ID" -f body="COMPLETE_UPDATED_BODY"

# update — labels are replaced wholesale; assignees replace unless prefixed with +/-
glab issue update N -R $R -t "New title" -d "New body"
glab issue update N -R $R -l scope:name
glab issue update N -R $R -a @me

# close / reopen
glab issue close N -R $R
glab issue reopen N -R $R
```

## Work-item hierarchy

GitLab's native hierarchy is typed: an issue can parent task work items. A task
has its own title, description, labels, assignee, comments, and lifecycle, but
is not an issue-to-issue sub-issue. Use this adapter when a workflow needs a
child ticket under an issue.

```bash
# create a child task; the response includes the task's iid and numeric id
glab api -X POST "projects/GROUP%2FREPO/issues" \
  -f title="Child task" \
  -f description="body" \
  -f issue_type=task

# attach the task to its parent issue; quick actions run when the note is saved
glab issue note TASK_IID -R $R -m "/set_parent #PARENT_IID"

# verify the parent relationship
glab api graphql -f query='query($id: WorkItemID!) { workItem(id: $id) { features { hierarchy { parent { id iid title } } } } }' \
  -F id="$TASK_ID"

# list direct child tasks of a parent work item
glab api graphql -f query='query($fullPath: ID!, $parentId: WorkItemID!, $after: String) { project(fullPath: $fullPath) { workItems(parentIds: [$parentId], types: [TASK], first: 100, after: $after) { nodes { id iid title state features { assignees { assignees { nodes { username } } } } } pageInfo { hasNextPage endCursor } } } }' \
  -F fullPath="$R" \
  -F parentId="$PARENT_ID" \
  -F after=null
```

The REST response returns a numeric database id. Convert it to the GraphQL
work-item id format `gid://gitlab/WorkItem/<id>` before assigning `TASK_ID` or
`PARENT_ID`. The REST issue-create endpoint has no direct `parent_id` field; the
two-step create-and-attach sequence is intentional. If more than 100 child
tasks exist, repeat the query with `after` set to `pageInfo.endCursor` while
`pageInfo.hasNextPage` is true.

## Issue links (blocked-by / blocking)

Relationships outside parentage are **issue links** with a `link_type`:
`relates_to`, `blocks`, or `is_blocked_by`. Set them via the API — the project
id in the path is the URL-encoded project path:

```bash
# this issue is blocked by issue 2 of the same project
glab api -X POST "projects/GROUP%2FREPO/issues/N/links" -f target_project_id=GROUP%2FREPO -f target_issue_iid=2 -f link_type=is_blocked_by

# this issue blocks issue 2
glab api -X POST "projects/GROUP%2FREPO/issues/N/links" -f target_project_id=GROUP%2FREPO -f target_issue_iid=2 -f link_type=blocks

# list an issue's links
glab api "projects/GROUP%2FREPO/issues/N/links"
```

GitLab treats "blocked" as a workflow signal, not a hard gate — closing a blocker does not auto-close the blocked issue.

## Native Stacked Merge Requests

GitLab stacks are represented by native merge-request source and target branch
relationships. The forge skill owns synchronization and branch maintenance
through explicit GitLab API and Git operations; the workflow owns only the
planned topology and normalized-state reconciliation.

```bash
# inspect the native topology before maintenance
glab mr list -R "$R" -A -F json \
  --jq '[.[] | {record_id:(.iid|tostring),source_branch:.source_branch,target_branch:.target_branch,state:.state}]'

# after a lower layer is merged, rebase a downstream merge request natively
glab api -X PUT "projects/$PROJECT/merge_requests/RECORD_ID/rebase"
rebase_complete=false
for attempt in 1 2 3 4 5; do
  REBASE_STATE="$(glab mr view RECORD_ID -R "$R" -F json \
    --jq '{rebase_in_progress,merge_error}')"
  if jq -e '.rebase_in_progress == false and .merge_error == null' <<<"$REBASE_STATE" >/dev/null; then
    rebase_complete=true
    break
  fi
  sleep 2
done
if [ "$rebase_complete" != true ]; then
  printf 'rebase did not complete; return publication-failed\n' >&2
  exit 1
fi

# update a rebased source branch without overwriting unrelated remote work
git -C "$REPO_DIR" fetch "$REMOTE"
git -C "$REPO_DIR" push --force-with-lease "$REMOTE" "SOURCE_BRANCH"

# retarget the review record through GitLab, then read its normalized state
glab mr update RECORD_ID -R "$R" --target-branch TARGET_BRANCH
glab mr view RECORD_ID -R "$R" -F json
```

Rebase completion and merge-request metadata are read back before the adapter
returns. A conflict or failed branch update preserves the source branch and
returns a retryable failure; it does not open another merge request. The native
merge-request UI remains a human fallback and inspection path when automation
is unavailable.

## Merge Requests And Delivery

Workflow skills read the provider-neutral operations and results in
[`forge-pr-delivery-contract.md`](../../shared/forge-pr-delivery-contract.md)
when publishing or maintaining a merge request. These are the GitLab adapter
recipes: GitLab owns the command syntax and response fields, then returns the
contract's `record_id`, `url`, `source_branch`, `target_branch`, `head_sha`, and
normalized `state`.

```bash
# create — source branch must be pushed; -b is the target branch
BASE_BRANCH="$(glab api "projects/GROUP%2FREPO" | jq -r '.default_branch')"
MR_URL="$(glab mr create -R $R -t "Title" -d "body" -s SOURCE_BRANCH -b "$BASE_BRANCH" -l scope:name -y)"
glab mr view "$MR_URL" -R $R -F json \
  --jq '{record_id:(.iid|tostring),url:.web_url,title,body:.description,source_branch:.source_branch,target_branch:.target_branch,head_sha:(.sha // .diff_refs.head_sha),state:(if .state == "opened" then "open" elif .state == "merged" then "merged" else "closed" end)}'

# REST create fallback — the response is JSON; normalize it through view when
# the CLI create command is unavailable or its output is ambiguous
glab api -X POST "projects/GROUP%2FREPO/merge_requests" \
  -f source_branch=SOURCE_BRANCH -f target_branch=TARGET_BRANCH \
  -f title="Title" -f description="body" \
  --jq '{record_id:(.iid|tostring),url:.web_url,title,body:.description,source_branch:.source_branch,target_branch:.target_branch,head_sha:(.sha // .diff_refs.head_sha),state:(if .state == "opened" then "open" elif .state == "merged" then "merged" else "closed" end)}'

# find — reconcile an ambiguous create by source branch before retrying
glab mr list -R $R --source-branch SOURCE_BRANCH -F json \
  --jq 'if length > 1 then error("multiple open merge requests for source branch") elif length == 0 then {record:null} else .[0] | {record:{record_id:(.iid|tostring),url:.web_url,title,body:.description,source_branch:.source_branch,target_branch:.target_branch,head_sha:(.sha // .diff_refs.head_sha),state:"open"}} end'

# lifecycle find — include merged and closed records when reconciling a rerun
glab mr list -R $R --source-branch SOURCE_BRANCH -A -F json \
  --jq 'if length > 1 then error("multiple merge requests for source branch") elif length == 0 then {record:null} else .[0] | {record:{record_id:(.iid|tostring),url:.web_url,title,body:.description,source_branch:.source_branch,target_branch:.target_branch,head_sha:(.sha // .diff_refs.head_sha),state:(if .state == "opened" then "open" elif .state == "merged" then "merged" else "closed" end)}} end'

# REST find fallback — filter open records by branch identity, then normalize
glab api "projects/GROUP%2FREPO/merge_requests?state=opened&source_branch=SOURCE_BRANCH" --paginate \
  --jq 'if length > 1 then error("multiple open merge requests for source branch") elif length == 0 then {record:null} else .[0] | {record:{record_id:(.iid|tostring),url:.web_url,title,body:.description,source_branch:.source_branch,target_branch:.target_branch,head_sha:(.sha // .diff_refs.head_sha),state:"open"}} end'

# lifecycle REST find — include merged and closed records during reconciliation
glab api "projects/GROUP%2FREPO/merge_requests?state=all&source_branch=SOURCE_BRANCH" --paginate \
  --jq 'if length > 1 then error("multiple merge requests for source branch") elif length == 0 then {record:null} else .[0] | {record:{record_id:(.iid|tostring),url:.web_url,title,body:.description,source_branch:.source_branch,target_branch:.target_branch,head_sha:(.sha // .diff_refs.head_sha),state:(if .state == "opened" then "open" elif .state == "merged" then "merged" else "closed" end)}} end'

# view — return the current provider response normalized to the shared record
glab mr view RECORD_ID -R $R -F json \
  --jq '{record_id:(.iid|tostring),url:.web_url,title,body:.description,source_branch:.source_branch,target_branch:.target_branch,head_sha:(.sha // .diff_refs.head_sha),state:(if .state == "opened" then "open" elif .state == "merged" then "merged" else "closed" end)}'

# update — edit provider fields, then read the authoritative current head
glab mr update RECORD_ID -R $R -t "Title" -d "body" -l "scope:name"
glab mr view RECORD_ID -R $R -F json \
  --jq '{record_id:(.iid|tostring),url:.web_url,title,body:.description,source_branch:.source_branch,target_branch:.target_branch,head_sha:(.sha // .diff_refs.head_sha),state:(if .state == "opened" then "open" elif .state == "merged" then "merged" else "closed" end)}'

# retarget — use GitLab's native target update; do not simulate stack behavior
glab mr update RECORD_ID -R $R --target-branch TARGET_BRANCH
glab mr view RECORD_ID -R $R -F json \
  --jq '{record_id:(.iid|tostring),url:.web_url,title,body:.description,source_branch:.source_branch,target_branch:.target_branch,head_sha:(.sha // .diff_refs.head_sha),state:(if .state == "opened" then "open" elif .state == "merged" then "merged" else "closed" end)}'

# publication_failure — classify command, auth, permissions, and publication failures
# as retryable while preserving the pushed branch and issue; never fabricate a record.
# Map exit 127 to tooling-unavailable, auth failures or HTTP 401 to
# authentication-required, HTTP 403 to permission-denied, and transient 408,
# 429, 500, or 503 publication errors to publication-failed. Return
# retryable=true, publication_exists=false for a known unsuccessful operation or
# publication_exists=unknown for an ambiguous create, plus preserved branch and
# issue state. Reconcile an ambiguous create with find by source branch before
# retrying; never blindly create a second record.
# The returned failure includes:
# operation: create | find | view | update | retarget
# failure_class: tooling-unavailable | authentication-required | permission-denied | publication-failed
# retryable: true
# publication_exists: false | unknown
# preserved_branch: true
# preserved_issue: true
glab auth status
glab mr create -R $R -t "Title" -d "body" -s SOURCE_BRANCH -b TARGET_BRANCH -y

# list / view
glab mr list -R $R -F json
glab mr list -R $R -A -F json                          # all states
glab mr view N -R $R -F json

# approve / comment
glab mr approve N -R $R
glab mr note N -R $R -m "text"

# merge — squash keeps history clean; -d removes the source branch
glab mr merge N -R $R -s -d -y
```

Represent a stack through source and target branch topology: each merge
request's source branch targets its predecessor, and the lowest branch targets
the default branch. GitLab's native merge-request UI is retained for human
fallback and inspection, including creating, viewing, retargeting, and
resolving a merge request when automation is unavailable. UI actions do not
replace the machine-readable adapter result. The experimental `glab stack sync` is
not the machine contract; use the explicit operations above and reconcile
native state by branch identity.

Retry transport failures and HTTP 408, 429, 500, and 503 with bounded backoff.
Treat missing tooling, authentication, and project access as retryable
prerequisite failures, not as publication. Stop before claiming a merge
request exists whenever the normalized result is absent or cannot be verified.

## Raw API escape hatch

For anything without a native subcommand, use the API directly:

```bash
glab api -X POST "projects/GROUP%2FREPO/issues" -f title="T" -f description="D" -f labels="scope:name"
glab api "projects/GROUP%2FREPO/issues" --paginate       # all pages
glab api -X POST "projects/GROUP%2FREPO/issues/N/notes" -f body="text"   # raw comment
```

## Gotchas

- The JSON output flag differs by command: `-O json` on issues, `-F json` on MRs. `--jq` filters the JSON output of list commands.
- `glab issue update -l` replaces the label set; to add one label without losing others, pass all desired labels.
- `glab issue create`/`glab mr create` prompt before submitting unless `-y` is passed — always include it in agent invocations.
- Project paths in API calls are URL-encoded: `GROUP/REPO` becomes `GROUP%2FREPO`.

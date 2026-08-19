---
name: gitlab
description: Work with GitLab — issues, work-item hierarchy, merge requests, labels, projects, and issue links. Exact command recipes backed by the glab CLI. Use whenever a task queries or modifies GitLab issues, MRs, labels, projects, hierarchy, or relationships, or when another skill needs a GitLab operation.
compatibility: Requires the glab CLI (glab-cli/glab) and GitLab authentication.
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

## Conventions

- **Always target the project explicitly**: `-R GROUP/REPO` (or `OWNER/REPO`, or a full URL). Without it, glab uses the current git remote — which is the wrong project when the task targets another one.
- **Machine-readable output**: pass the JSON output flag (`-O json` on issues, `-F json` on MRs) and read the JSON. Never parse human-readable output.
- **Structured labels**: use the taxonomy in [`label-taxonomy.md`](../../shared/label-taxonomy.md) — every label is `scope:name` with a `--color` hex from [`color-palette.md`](../../shared/color-palette.md).
- **Labels must exist before use**: `glab issue create --label X` fails if X doesn't exist. Create it first (recipe below) — that call is idempotent.
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

Create every label from the taxonomy before the first issue references it. Verify:

```bash
glab label list -R $R
glab label edit -n scope:name -c HEX -R $R
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

## Merge requests

```bash
# create — source branch must be pushed; -b is the target branch
glab mr create -R $R -t "Title" -d "body" -s SOURCE_BRANCH -b main -l scope:name --remove-source-branch -y

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

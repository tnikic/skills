---
name: github
description: Work with GitHub — issues, pull requests, labels, repositories, and issue hierarchy (parent/child, blocked-by/blocking). Exact command recipes backed by the gh CLI. Use whenever a task queries or modifies GitHub issues, PRs, labels, or repos, or when another skill needs a GitHub operation.
compatibility: Requires the gh CLI (github.com/cli/cli) and GitHub authentication.
---

# GitHub forge skill

Command recipes for every GitHub operation the pipeline needs. Run the recipe as written — the agent's thinking belongs to the result, not the syntax.

## Setup and auth

```bash
gh auth status          # verify the active account
gh auth login           # authenticate (device flow) if not signed in
```

GitHub Enterprise users pass `--hostname <host>` on auth. The active account is used for all calls.

## Conventions

- **Always target the repo explicitly**: `-R OWNER/REPO`. Without it, gh uses the current git remote — which is the wrong repo when the task targets another one.
- **Machine-readable output**: pass `--json <fields>` and read the JSON. Never parse human-readable output. Fields are listed in each recipe; `gh issue view --json` supports `number,title,state,body,labels,assignees,author,createdAt,updatedAt,url,comments,parent,subIssues,blockedBy,blocking`.
- **Structured labels**: use the taxonomy in [`label-taxonomy.md`](../../shared/label-taxonomy.md) — every label is `scope:name` with a `--color` hex from [`color-palette.md`](../../shared/color-palette.md).
- **Labels must exist before use**: `gh issue create --label X` and `gh issue edit --add-label X` fail with "label not found" if X doesn't exist. Create it first (recipe below) — that call is idempotent.
- In the recipes, `R=OWNER/REPO` — set it once per session, then copy recipes verbatim.

## Repositories

```bash
gh repo create NAME --private            # create; use --public or --internal for visibility
gh repo list -R OWNER --json name,visibility --limit 30
gh repo delete OWNER/NAME --yes          # permanent, cannot be undone
```

## Labels

```bash
gh label create scope:name --color HEX --description "..." --force -R $R
```

`--force` makes it idempotent: create when missing, recolor when present. Create every label from the taxonomy before the first issue references it. Verify:

```bash
gh label list -R $R --json name,color --limit 100
gh label edit scope:name --color HEX -R $R
```

## Issues

```bash
# create — labels must already exist; --assignee @me claims the issue
gh issue create -R $R -t "Title" -b "body" -l scope:name -l scope:name --assignee @me

# view — add -c to include comments (same flag works with --json)
gh issue view N -R $R --json number,title,state,body,labels,assignees,author,createdAt,url
gh issue view N -R $R -c --json comments

# list — state: open (default), closed, all
gh issue list -R $R --json number,title,state,labels,assignees --limit 100
gh issue list -R $R --state closed --json number,title,labels --limit 100
gh issue list -R $R --label scope:name --json number,title --limit 100

# frontier — open, unclaimed, oldest first (search syntax: GitHub issue search)
gh issue list -R $R --search 'is:open no:assignee sort:created-asc' --json number,title,labels --limit 50

# comment
gh issue comment N -R $R -b "text"

# edit an issue comment — read it, change only satisfied markers, then send the complete body
gh api "/repos/$R/issues/comments/COMMENT_ID" --jq '.body'
gh api --method PATCH "/repos/$R/issues/comments/COMMENT_ID" -f body="COMPLETE_UPDATED_BODY"

# edit — labels and assignees are additive; the label must exist first
gh issue edit N -R $R --title "New title" --body "New body"
gh issue edit N -R $R --add-label scope:name --remove-label scope:name
gh issue edit N -R $R --add-assignee @me --remove-assignee login

# close / reopen
gh issue close N -R $R --reason completed --comment "closing note"   # reasons: completed, not planned, duplicate
gh issue reopen N -R $R
```

## Issue hierarchy

GitHub models the pipeline's relationships natively: **sub-issues** (parent/child) and **blocking** (blocked-by/blocking). Both are set at create time or by editing.

```bash
# create with relationships
gh issue create -R $R -t "Child" -b "..." --parent N            # sub-issue of N
gh issue create -R $R -t "Task" -b "..." --blocked-by N          # N blocks this
gh issue create -R $R -t "Task" -b "..." --blocking N            # this blocks N

# add/remove relationships on existing issues
gh issue edit N -R $R --add-sub-issue M --remove-sub-issue M
gh issue edit N -R $R --add-blocked-by M --remove-blocked-by M
gh issue edit N -R $R --add-blocking M --remove-blocking M
gh issue edit N -R $R --parent M          # set parent; --remove-parent clears it

# query relationships
gh issue view N -R $R --json parent,subIssues,blockedBy,blocking
gh api "/repos/$R/issues/N/sub_issues" --paginate   # plain REST list of child issue numbers
```

## Pull Requests And Delivery

Workflow skills read the provider-neutral operations and results in
[`forge-pr-delivery-contract.md`](../../shared/forge-pr-delivery-contract.md)
when publishing or maintaining a pull request. These are the GitHub adapter
recipes: GitHub owns the command syntax and response fields, then returns the
contract's `record_id`, `url`, `source_branch`, `target_branch`, `head_sha`, and
normalized `state`.

```bash
# create — source branch must be pushed; base is the target branch
BASE_BRANCH="$(gh repo view -R $R --json defaultBranchRef --jq '.defaultBranchRef.name')"
PR_URL="$(gh pr create -R $R --title "Title" --body "body" --head SOURCE_BRANCH --base "$BASE_BRANCH" -l scope:name)"
gh pr view "$PR_URL" -R $R --json number,url,state,title,body,headRefName,baseRefName,headRefOid \
  --jq '{record_id:(.number|tostring),url,title,body,source_branch:.headRefName,target_branch:.baseRefName,head_sha:.headRefOid,state:(if .state == "OPEN" then "open" elif .state == "MERGED" then "merged" else "closed" end)}'

# find — reconcile an ambiguous create by source branch before retrying
gh pr list -R $R --head SOURCE_BRANCH --state open \
  --json number,url,state,title,body,headRefName,baseRefName,headRefOid \
  --jq 'if length > 1 then error("multiple open pull requests for source branch") elif length == 0 then {record:null} else .[0] | {record:{record_id:(.number|tostring),url,title,body,source_branch:.headRefName,target_branch:.baseRefName,head_sha:.headRefOid,state:"open"}} end'

# view — return the current provider response normalized to the shared record
gh pr view RECORD_ID -R $R --json number,url,state,title,body,headRefName,baseRefName,headRefOid \
  --jq '{record_id:(.number|tostring),url,title,body,source_branch:.headRefName,target_branch:.baseRefName,head_sha:.headRefOid,state:(if .state == "OPEN" then "open" elif .state == "MERGED" then "merged" else "closed" end)}'

# update — edit provider fields, then read the authoritative current head
gh pr edit RECORD_ID -R $R --title "Title" --body "body" --add-label "scope:name"
gh pr view RECORD_ID -R $R --json number,url,state,title,body,headRefName,baseRefName,headRefOid \
  --jq '{record_id:(.number|tostring),url,title,body,source_branch:.headRefName,target_branch:.baseRefName,head_sha:.headRefOid,state:(if .state == "OPEN" then "open" elif .state == "MERGED" then "merged" else "closed" end)}'

# retarget — use GitHub's native target update; do not simulate stack behavior
gh pr edit RECORD_ID -R $R --base TARGET_BRANCH
gh pr view RECORD_ID -R $R --json number,url,state,title,body,headRefName,baseRefName,headRefOid \
  --jq '{record_id:(.number|tostring),url,title,body,source_branch:.headRefName,target_branch:.baseRefName,head_sha:.headRefOid,state:(if .state == "OPEN" then "open" elif .state == "MERGED" then "merged" else "closed" end)}'

# publication_failure — classify command, auth, permission, and publication failures
# as retryable while preserving the pushed branch and issue; never fabricate a record.
# Map exit 127 to tooling-unavailable, auth failures to authentication-required,
# permissions failures to permission-denied, and transient 408, 429, 500, or 503
# publication errors to publication-failed. Return retryable=true,
# publication_exists=false, and the preserved branch and issue state for each
# class.
gh auth status
gh pr create -R $R --title "Title" --body "body" --head SOURCE_BRANCH --base TARGET_BRANCH

# list / view
gh pr list -R $R --json number,title,state,labels,headRefName,baseRefName --limit 100
gh pr view N -R $R --json number,title,state,body,labels,headRefName,baseRefName,mergeable

# review — you cannot approve your own PR (gh rejects it); use --comment or --request-changes
gh pr review N -R $R --approve -b "text"
gh pr review N -R $R --comment -b "text"

# merge — squash keeps history clean; --delete-branch removes head branch
gh pr merge N -R $R --squash --delete-branch
```

## Raw API escape hatch

For anything without a native subcommand, use the REST API directly:

```bash
gh api "/repos/$R/issues" -f title="T" -f body="B" --method POST        # -f = string field, -F = typed
gh api "/repos/$R/issues/N/labels" -X DELETE                            # remove all labels
gh api graphql -f query='query { repository(owner: "O", name: "N") { issue(number: N) { title } } }'
```

## Gotchas

- `gh issue edit` has no `--json`/`--jq` output flags — run it, then re-view with `--json`.
- `gh issue view --json` with several relationship fields at once may return a JSON array instead of an object — if that happens, request the fields one at a time.
- `gh issue list --label` does not take comma lists of labels; repeat `--label` per label.
- Repo creation and deletion require `repo` and `delete_repo` token scopes; check with `gh auth status`.

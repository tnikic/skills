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

## Pull Requests And Status

Workflow skills read the normalized operations and outcomes in
[`forge-pr-status-contract.md`](../../shared/forge-pr-status-contract.md) when
creating or updating PRs, assigning reviewers, processing comments, or polling
required checks.
These recipes are the GitHub adapter: they preserve the PR head SHA and map
GitHub responses to the shared outcomes instead of making workflow decisions.

```bash
# create_pr — head branch must be pushed; use the declared impact or `normal` when absent
BASE_BRANCH="$(gh repo view -R $R --json defaultBranchRef --jq '.defaultBranchRef.name')"
PR_URL="$(gh pr create -R $R --title "Title" --body "body" --head HEADBRANCH --base "$BASE_BRANCH" \
  --label impact:$IMPACT --reviewer REVIEWER)"
gh pr view "$PR_URL" -R $R --json number,url,state,headRefName,baseRefName,headRefOid \
  --jq '{number,url,state,base_branch:.baseRefName,head_branch:.headRefName,head_sha:.headRefOid}'
gh pr view N -R $R --json number,url,state,headRefName,baseRefName,headRefOid

# get_pr — return normalized metadata; head_sha is the exact value used for readiness
gh pr view N -R $R --json number,url,state,headRefName,baseRefName,headRefOid,body,reviewRequests \
  --jq '{number,url,state,base_branch:.baseRefName,head_branch:.headRefName,head_sha:.headRefOid,body,reviewRequests}'

# list_open_prs — return normalized metadata for every open PR without a page cap
gh api "/repos/$R/pulls?state=open&per_page=100" --paginate \
  --jq '.[] | {number,url:.html_url,state,base_branch:.base.ref,head_branch:.head.ref,head_sha:.head.sha,body}'

# find_pr — find the open PR for a combined head branch
gh pr list -R $R --head HEADBRANCH --state open \
  --json number,url,state,headRefName,baseRefName,headRefOid \
  --jq 'if length > 1 then error("multiple open PRs for head branch") elif length == 0 then empty else .[0] | {number,url,state,base_branch:.baseRefName,head_branch:.headRefName,head_sha:.headRefOid} end'

# update_pr — update an existing combined PR and return its current metadata
gh pr edit N -R $R --title "Title" --body "body" --add-label "impact:$IMPACT"
gh pr view N -R $R --json number,url,state,headRefName,baseRefName,headRefOid \
  --jq '{number,url,state,base_branch:.baseRefName,head_branch:.headRefName,head_sha:.headRefOid}'

# retarget_pr — use GitHub's native stack behavior; do not simulate stack
# ordering, rebases, or merges in a workflow skill
gh pr edit N -R $R --base "$BASE_BRANCH"
gh pr view N -R $R --json number,url,state,headRefName,baseRefName,headRefOid \
  --jq '{number,url,state,base_branch:.baseRefName,head_branch:.headRefName,head_sha:.headRefOid}'

# assign_reviewer — request or re-request a human reviewer
gh pr edit N -R $R --add-reviewer REVIEWER

# list_review_comments — include inline review comments and PR conversation comments
gh api "/repos/$R/pulls/N/comments?per_page=100" --paginate
gh api "/repos/$R/issues/N/comments?per_page=100" --paginate
# Resolve workflow_author from the authenticated account before classification.
gh api user --jq '.login'
# Normalize each returned comment with comment_id=.id, author=.user.login,
# body=.body, timestamp=.created_at, processed=<audit rule>, and discussion_id
# equal to the root ID reached by walking each .in_reply_to_id chain, otherwise .id. For issue comments
# without native threads, match processed markers by the listed comment IDs.

# reply_and_mark_processed — reply to an inline comment or add a PR-thread marker
gh api --method POST "/repos/$R/pulls/N/comments/COMMENT_ID/replies" \
  -f body="Processed comment IDs: COMMENT_ID\nReply [review-analysis processed:$BATCH_ID]"
gh api --method POST "/repos/$R/issues/N/comments" \
  -f body="Processed comment IDs: COMMENT_ID\nReply [review-analysis processed:$BATCH_ID]"

# reply — reply without changing processed state (used for clarification)
gh api --method POST "/repos/$R/pulls/N/comments/COMMENT_ID/replies" \
  -f body="[review-analysis clarification:$BATCH_ID]\nClarification comment IDs: COMMENT_ID\nQuestion"
gh api --method POST "/repos/$R/issues/N/comments" \
  -f body="[review-analysis clarification:$BATCH_ID]\nClarification comment IDs: COMMENT_ID\nQuestion"

# discover_required_checks — inspect protection and rulesets; absence means configuration-gap
gh api -X GET "/repos/$R/branches/BASE_BRANCH/protection/required_status_checks" \
  --jq '{required: .contexts}'
gh api -X GET "/repos/$R/rulesets?per_page=100"
gh api -X GET "/repos/$R/rulesets/RULESET_ID"

# status_for_head — query checks for the exact SHA from get_pr
gh api -X GET "/repos/$R/commits/$HEAD_SHA/check-runs?per_page=100"
gh api -X GET "/repos/$R/commits/$HEAD_SHA/status?per_page=100"

# list / view
gh pr list -R $R --json number,title,state,labels,headRefName,baseRefName --limit 100
gh pr view N -R $R --json number,title,state,body,labels,headRefName,baseRefName,mergeable

# review — you cannot approve your own PR (gh rejects it); use --comment or --request-changes
gh pr review N -R $R --approve -b "text"
gh pr review N -R $R --comment -b "text"

# merge — squash keeps history clean; --delete-branch removes head branch
gh pr merge N -R $R --squash --delete-branch
```

For each returned comment, set `processed=true` when its own body contains the
shared `[review-analysis processed:<batch-id>]` marker, or when a batch reply
explicitly lists that comment ID. A marker never processes unrelated comments
in the same discussion. Accept either condition only when the comment or
reply author equals workflow_author. Omit audit comments from the actionable review queue.
Replies retain the root discussion ID for inline review threads.
Map GitHub's check-runs and combined-status fields through the shared status
matrix. Ruleset-only repositories are valid; return `configuration-gap` only
when neither branch protection nor applicable ruleset requirements can be
discovered. Optional checks remain evidence only.

The adapter reports only the shared outcomes: `pending`, `success`, `failure`,
`cancelled`, `stale`, `timeout`, and `configuration-gap`.

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

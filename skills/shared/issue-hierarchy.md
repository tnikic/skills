# Issue Hierarchy

This reference defines the relationship contract shared by ticket workflows.
Forge skills own the command recipes; consumers use the matching forge's
recipes rather than deriving commands or assuming one forge's field names.

## Parent And Child

- **GitHub** — an issue can own child issues through native sub-issues. The
  parent's `parent` and `subIssues` fields are available through the GitHub
  skill's JSON recipes.
- **GitLab** — an issue can own child **task** work items. A child ticket is
  created with `issue_type=task`, attached with `/set_parent`, and queried with
  the GitLab work-item hierarchy recipe. A task carries its own title,
  description, labels, assignee, comments, and lifecycle, but it is not an
  issue-to-issue sub-issue equivalent.

Preserve the ticket body, labels, and acceptance criteria across both adapters.
When a workflow needs a parent or child, use the forge-specific hierarchy
recipe and report the actual work-item type in the result.

## Blocking

Blocking is separate from parentage. GitHub exposes `blockedBy` and `blocking`;
GitLab exposes `is_blocked_by` and `blocks` issue links. A ticket is unblocked
only when every linked blocker is closed.

## Consumer Rule

Parent-dependent steps must query the matching forge's hierarchy before acting.
Do not infer parentage from issue text, labels, or a forge-specific JSON field.

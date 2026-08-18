# Dedicated Merge-Conflict Repair

The fleet manager dispatches a dedicated repair skill in an isolated worktree after merges make an open PR stale or conflicted; the repair rebases onto the current base and reruns CI. Mechanical in-scope conflicts are repaired without changing ticket state, while semantic conflicts stop for human intent rather than being treated as fresh implementation work.

# Separate PR Workflow Orchestration

The pull-request route uses a separate user-invoked workflow to orchestrate branch preparation, implementation, commit finalization, and PR publication. `/implement` remains the implementation source of truth, `/commit` remains the universal commit and push gate, and GitHub or GitLab skills own forge-specific operations; this preserves the ordinary route without duplicating implementation behavior.

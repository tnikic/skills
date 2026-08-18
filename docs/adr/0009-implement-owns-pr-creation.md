# Implement Owns PR Creation

The `implement` skill owns the transition from completed work to an open PR: it pushes the feature branch and creates the PR, while `commit` remains the universal commit-quality gate. This keeps the PR as a thin projection of the ticket, moves issue closure to merge time, and keeps commit messages free of forge-specific `Closes` metadata.

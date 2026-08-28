# Branch Handoff Through the Commit Gate

The PR workflow creates or selects a non-default implementation branch before implementation, then invokes the universal commit gate to commit and push the current branch before forge-native PR publication. This prevents direct default-branch pushes while preserving one commit and push policy for both ordinary and PR routes.

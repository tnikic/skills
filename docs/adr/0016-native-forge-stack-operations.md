# Native Forge Stack Operations

The PR workflow uses native GitHub and GitLab stack capabilities exposed by their forge skills, including GitHub's `gh-stack` operations, rather than adding Graphite as a dependency, adapter, or fallback. This keeps stack semantics with the forge that owns the pull request or merge request.

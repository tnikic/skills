# Keep commit execution behind one gate

`/commit` owns staging, safety checks, quality and documentation gates, commit-message approval, local commit creation, and pushing. `/conventional-commits` supplies the message policy to that gate rather than competing as a second execution workflow; issue closure remains with the workflow that owns the issue. This keeps every produced commit on the same safety path while separating execution from message structure.

## Considered Options

- **Let each workflow commit and push independently** — rejected: checks and execution would diverge between workflows.
- **Make `/conventional-commits` the execution workflow** — rejected: message structure does not own staging, repository gates, or remote publication.

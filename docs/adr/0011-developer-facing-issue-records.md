# Keep issue records developer-facing

Issue bodies and comments describe the work, decisions, evidence, and outcomes in developer language. Workflows use native tracker metadata such as labels, sub-issues, and blocked-by relationships, while skill names and internal continuation procedure stay in the agent context. This preserves public readability without giving up machine-readable coordination.

## Considered Options

- **Expose workflow procedure in issue prose** — rejected: developers would need to understand the agent setup to follow the work.
- **Avoid tracker metadata** — rejected: native labels and relationships provide useful, readable progress and dependency history.

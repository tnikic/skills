# Agent-generated CI pipelines for bootstrapped projects

This decision governs repositories aligned by the `bootstrap` skill. It does
not prescribe the command portfolio or CI configuration of this skills
repository itself.

CI pipelines are generated fresh by the agent from a language profile (tools +
constraints), not stored as YAML templates in the target repo. Hardcoded
templates go stale. The version pinning rule requires researching the latest
stable action or tool version before every generation, so the pipeline is
current at the time it is created.

The same language profile drives the generated pre-commit hook and CI command:
the profile's `check` target is the fast local gate, and its `test` target is
the CI gate. Exact commands and additional targets vary by profile; the
profile remains the source of truth.

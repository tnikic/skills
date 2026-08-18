# Dedicated skill workflows for skill work

Skill authoring and skill architecture work use dedicated skills:

- `/implement-skill` implements a new skill or a requested change from a clear
  request, spec, or issue.
- `/improve-skill` audits an existing skill, presents bounded improvement
  candidates, and edits only the candidate the user selects.
- `/review-skill` reviews a skill diff across Standards, Spec, and Coverage
  without editing it.

The authoring and architecture workflows use `writing-for-agents` as their
writing reference and keep the user as the invocation index. The review
workflow is model-invoked so implementation work can request it automatically.
Together they make skill-specific reasoning visible without adding unnecessary
always-loaded descriptions.

`make test` remains a deterministic, offline repository gate. It checks
machine-readable structure and known repository/workflow invariants; it does
not attempt to prove that an agent follows a prose skill well.

## Rejected options

- **Model-backed `make eval`** — rejected as the primary interface: it needs a
  provider adapter, credentials, network policy, repeated trials, and
  subjective grading. Those concerns are expensive and nondeterministic for a
  repository gate.
- **One generic skill-work tool** — rejected: implementation, architecture, and
  review have different stopping points. Implementation changes an agreed
  contract; architecture presents alternatives and waits for a decision;
  review reports findings without editing.
- **Phrase checks as behavioral tests** — rejected: literal wording checks can
  pass while an agent behaves incorrectly and can freeze incidental prose.

When empirical evidence is needed, the dedicated workflows may run a fresh
agent review or a task fixture as an explicit, user-directed step. That
evidence remains separate from `make test`.

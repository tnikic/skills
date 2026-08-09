# Agent-generated CI pipelines, not hardcoded templates

CI pipelines are generated fresh by the agent from a language profile (tools + constraints), not stored as YAML templates in the repo. Hardcoded templates go stale — the agent pins GitHub Actions v7 because v9 didn't exist at training time. The version pinning rule requires researching latest stable before every generation, so the pipeline is always current.

The same language profile drives the pre-commit hook (`make check`: lint, fmt, typecheck) and the CI pipeline (`make test`: full suite, vuln scan, code review). One definition, two targets, both agent-rendered.

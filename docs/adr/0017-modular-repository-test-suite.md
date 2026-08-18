# Modular Repository Test Suite

The repository test suite is split into three concern-based shell modules behind
the unchanged `make test` entrypoint. A small runner executes them sequentially
and reports each concern separately while preserving a non-zero aggregate exit
status.

The selected design is the smallest durable improvement for this repository:

- Keep the monolith only as a rollback reference, not as the active suite. It
  has no migration cost but creates unclear ownership and first-failure-only
  diagnostics.
- Use concern-based shell modules with a shared assertion helper. This keeps
  deterministic offline execution and avoids a new dependency while isolating
  repository, skill/workflow, and forge-adapter changes.
- Do not add a test framework. The suite validates Markdown, shell, Make, and
  YAML-shaped contracts rather than application code, so a framework would add
  setup and dependency surface without improving the tested seams.
- Do not generate contract checks. The assertions intentionally name the
  required workflow and forge behavior; generated checks would hide the
  contract and weaken review signal.
- Do not run modules in parallel. Stable output and simple aggregate failure
  handling are more valuable than a small runtime reduction for this offline
  suite.

## Concern Map

The former `scripts/test.sh` assertions map as follows:

| Concern | Module | Preserved assertion groups |
| --- | --- | --- |
| Repository/Makefile/CI | `scripts/tests/repository-contracts.sh` | Required files; `check` and `test` targets; `make test` wiring; mise and direct-tool execution; missing-suite diagnostics; CI trigger/jobs; README quality-gate references |
| Skill/workflow | `scripts/tests/skill-workflow-contracts.sh` | `implement` checkbox ownership; branch and delivery mode rules; pre-PR review and correction loop; commit and PR handoff; exact-head readiness; issue selection and blocker state; code-review scope |
| Forge adapter | `scripts/tests/forge-adapter-contracts.sh` | GitHub/GitLab `find_pr` normalization; duplicate and no-match handling; comment editing; PR, reviewer, status, stack, and readiness recipes; normalized status outcomes; contract validators |

The modules retain the old assertion order within each concern and use the
same literal expectations. The former assertion locations are inventoried
below so future changes can check parity without guessing which contract moved.
A failure now includes its concern name, while the runner continues through
the remaining modules before returning failure.

### Assertion Inventory

- Repository/Makefile/CI: former lines 118-120 each repository file assertion; 127-130
  Makefile target assertions; 133-135 test recipe assertions; 165-176 mise
  tool assertions; 190-196 direct-tool fallback assertions; 199-203 missing
  suite assertions; 205 workflow trigger; 206-207 workflow jobs; 208-210
  README quality-gate assertions.
- Skill/workflow: former lines 121-122 skill file assertions; 211-221 checkbox source and negative assertions;
  222-231 branch, review, metadata, and lifecycle assertions; 232-240 commit,
  PR, and ticket lifecycle assertions; 241-254 forge handoff, impact, reviewer,
  and readiness assertions; 255-266 issue-edit, PR metadata, and delivery-mode
  assertions; 267-277 combined and stacked delivery assertions; 278-290
  ordering assertions; 291-312 review-loop and re-entry assertions; 313-322
  gate ordering assertions; 323-327 code-review scope assertions; 328-334
  issue selection and blocker assertions; 335-336 obsolete wording negative
  assertions; 337-338 blocker-state fixture assertions.
- Forge adapter: former lines 79-103 `find_pr` extraction, no-match, single
  match, and duplicate assertions; 106-116 GitHub/GitLab fixture and branch
  assertions; 123-125 forge file assertions; 339-342 comment-edit recipe
  assertions; 344-354 normalized operation and outcome assertions; 355-368
  GitHub PR, status, stack, reviewer, and comment assertions; 369-384 GitLab
  equivalents; 386-388 validator assertions.

The repository suite also runs a temporary three-suite runner fixture: one
failing concern must produce a concern-specific diagnostic, later concerns
must still run, and the aggregate status must remain non-zero.

## Migration And Rollback

Migration is complete when all former assertions live in one of the three
modules, `scripts/test.sh` remains the runner invoked by `make test`, and the
full offline suite passes. New assertions belong to the concern module that
owns the contract; shared shell behavior belongs in `test_helpers.sh`.

Rollback is bounded to reverting this change: restore the former monolithic
`scripts/test.sh`, remove `scripts/tests/`, and leave the Makefile target
unchanged. No caller-facing command, dependency, or test promise changes.

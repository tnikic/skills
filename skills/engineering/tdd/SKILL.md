---
name: tdd
description: Test-driven development. Feedback-first — a runnable check before code, the smallest provable slice first, E2E as the final gate. Use when the user wants to build features or fix bugs test-first, mentions "red-green-refactor", wants integration tests, or wants to prove a vertical slice works end-to-end first.
---

# Test-Driven Development

TDD is the red → green loop. This skill is the reference that makes that loop produce tests worth keeping: which test types to write, what a good test is, where tests go, the anti-patterns, and the rules of the loop. Every section applies on every cycle — consult them before and during the loop, not after.

When exploring the codebase, read `docs/CONTEXT.md` (if it exists) so test names and interface vocabulary match the project's domain language, and respect ADRs in the area you're touching. Run the `check` target for static analysis and `test` for the test suite — see [`command-runner.md`](../../shared/command-runner.md) for detection and standard targets. If neither target exists, the command-runner module will report it — relay its message.

## The frame: feedback-first, not type-first

An agent needs a **runnable pass/fail check before code**, at the smallest provable slice — not a type-driven ordering. Unit tests written without a runnable check invite green-washing. Work in this order:

1. **Write the test list first.** Transient external state — a `test-list.md` file derived from the ticket's acceptance criteria. Drives ordering, one test at a time, marked off as they pass. **Never commit it**; delete it when the ticket is done — the committed tests are the record, not the plan file.
2. **First test: the thinnest vertical runnable check** through real seams — one request, one assertion, happy path. The smallest provable slice that proves the ticket's slice works.
3. **Minimal implementation to make it pass.**
4. **Drill down.** Unit tests for the logic that emerged, integration tests for the real seams, contract tests for external API surfaces — the [test-type taxonomy](../../shared/test-types.md) is the reference for what to write, not the order to write it in.
5. **Final gate: E2E.** Prove the feature through the user's path. Gate tests (smoke, E2E) may still trail the loop when the interface is new — you cannot test a deploy mechanism that does not exist. E2E is never the first step.

The project's Makefile or justfile is the authoritative portfolio of test targets — run `make help` or `just --list` to see available targets, do not re-research unless the user asks.

## What a good test is

Tests verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't. A good test reads like a specification — "user can checkout with valid cart" tells you exactly what capability exists — and survives refactors because it doesn't care about internal structure.

See [TESTS.md](TESTS.md) for examples and [MOCKING.md](MOCKING.md) for mocking guidelines.

## Seams — where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside. Tests live at seams, never against internals.

**Test only at pre-agreed seams.** Before writing any test, write down the seams under test and confirm them with the user. No test is written at an unconfirmed seam. You can't test everything — agreeing the seams up front is how testing effort lands on the critical paths and complex logic instead of every edge case.

Ask: "What's the public interface, and which seams should we test?"

## Anti-patterns

- **Cheating** — agent anti-patterns that fake a green: deleting or disabling a red test to make it pass; "looks done" without running the test; coding ahead of the test list. A test passes only when it runs and goes green.
- **Mocks as a cheating vector** — authoring a mock that fabricates the pass (see [MOCKING.md](MOCKING.md): prefer real seams for the vertical check; never author a mock that makes the test pass trivially).
- **Implementation-coupled** — mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). The tell: the test breaks when you refactor but behavior hasn't changed.
- **Tautological** — the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted equal to itself), so it passes by construction and can never disagree with the code. Expected values must come from an independent source of truth — a known-good literal, a worked example, the spec.
- **Horizontal slicing** — writing all tests first, then all implementation. Bulk tests verify _imagined_ behavior: you test the _shape_ of things rather than user-facing behavior, the tests go insensitive to real changes, and you commit to test structure before understanding the implementation. Work in **vertical slices** instead — one test → one implementation → repeat, each test a **tracer bullet** that responds to what the last cycle taught you.

## Rules of the loop

- **Red before green.** Write the failing test first, then only enough code to pass it. Don't anticipate future tests or add speculative features.
- **One slice at a time.** One seam, one test, one minimal implementation per cycle. The test list paces you — one test at a time, marked off as they pass.
- **Refactor in the green phase.** Refactoring happens after a test passes, never mixed with behavioral changes. Separate structural from behavioral changes, and re-run the tests after each refactor step. If a refactor step turns a test red, you mixed the two — undo and separate.
- **Gate tests may trail the loop.** Smoke and E2E tests can be written after the feature when the interface is new — see the final gate above. They still land before the ticket closes.
- **Test-first pairing is escalation, not default.** For larger slices or long runs, dispatch a tester subagent and an implementer subagent to parallelize — see [`subagent-dispatch.md`](../../shared/subagent-dispatch.md). Not the default: coverage review already provides post-hoc fresh-context scrutiny.

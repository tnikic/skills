# Command Runner

Single source of truth for detecting and invoking the project's command runner. Skills that need to run project targets (check, test, lint, fmt) read from here rather than reimplementing detection.

## Detection

Given a target name (e.g., `check`, `test`, `lint`, `fmt`), detect the runner and return the command:

- `make <target>` — if a `Makefile` exists in the repo root
- `just <target>` — if a `justfile` exists in the repo root
- Skip — if neither exists; report "No command runner configured — run /bootstrap to add one"

A repo with both a Makefile and justfile is an error — report it and stop.

## Standard targets

The project's standardized targets, defined in ADR-0002:

| Target | What it runs |
|--------|-------------|
| `check` | Lint, format, typecheck — fast, for pre-commit |
| `test` | Full suite, vuln scan, code review — comprehensive, for CI |
| `lint` | Linter only |
| `fmt` | Formatter only |

Skills invoke the target name, not the command. This file owns the mapping from target name to shell invocation.

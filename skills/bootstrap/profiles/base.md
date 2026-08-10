# Base Language Profile

Fallback for languages without a dedicated profile. No ecosystem-specific tools or conventions.

## Command runner

Detect from the repo. If none exists, use direct shell commands.

## Targets

| Target | Runs |
|--------|------|
| `check` | Lint + format + typecheck using whatever tooling is configured in the project |
| `test` | Run the project's test suite |

If no tooling is configured, `check` and `test` succeed trivially — the bootstrap creates the targets as placeholders.

## Layout

Preserve existing structure. No conventions imposed.

## CI

Detect the CI platform from the repo. Generate a minimal pipeline that runs `check` and `test`. Resolve platform-specific action versions at generation time.

## README

Apply the bootstrap's language-agnostic README template. No language-specific badges.

## Pre-commit hook

Run `check` via whatever command runner is available.

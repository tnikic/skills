# README Template

Bootstrap applies these rules to generate a project README. Not a fill-in-the-blanks template — the agent writes the README following these constraints.

## Sections

Generate these sections in order:

1. **Title + tagline** — project name as h1, one-line description of what it does
2. **Visual** — GIF for CLI projects, screenshot for web/libs. Omit if project type is undetermined
3. **Quick start** — 2-4 shell commands to install and run. The minimal viable path
4. **Link index** — pointers to `make help` (or `just help`), `CONTRIBUTING.md`, `CHANGELOG.md`. Do not restate their content

## Badges

Place below the title, centered. Use shields.io flat style.

| Badge | When |
|-------|------|
| CI build status | Always — link to the repo's CI pipeline |
| License | Always — auto-detect from repo license file |
| Language/runtime | Always — e.g. "Go 1.24", "Rust" |
| Version | Only when project version ≥ 0.1.0 — leave a placeholder the docs gate fills |

Badges present at version 0.0.0: CI, License, Language only. The version badge slot exists but is empty until the docs gate activates it on first release.

## Voice

- Conversational, like explaining to a colleague
- No em dashes
- Emojis only when carrying information — ⚠️ for warnings, not 🎉 for vibes
- One sentence per thought. Short paragraphs

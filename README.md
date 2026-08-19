# skills

Agent skills for the pi coding agent — bootstrap, capture, triage, implement, and more.

<p align="center">
  <img alt="License" src="https://img.shields.io/badge/license-Apache%202.0-blue?style=flat">
</p>

## Quick start

Clone into `~/.agents` (or wherever your agent looks for user skills):

```bash
git clone https://github.com/tnikic/skills.git ~/.agents
```

Skills are discovered automatically. Run `/bootstrap` in any repo to align it to the standard project shape, `/capture` to file a bug or idea, `/implement-skill` to create or change a skill, `/improve-skill` to audit a named skill or scan the portfolio, or `/review-skill` to review a skill diff.

## Dependencies

Some skills depend on external tools. Install with [mise](https://mise.jdx.dev/) (recommended) or your package manager of choice.

| Tool | Used by | Install (mise) |
|------|---------|----------------|
| [gh](https://github.com/cli/cli) | github (forge actions) | `mise use gh` |
| [glab](https://github.com/glab-cli/glab) | gitlab (forge actions) | `mise use glab` |
| [gitleaks](https://github.com/gitleaks/gitleaks) | capture (secrets stripping), bootstrap (check target) | `mise use gitleaks` |
| [lychee](https://github.com/lycheeverse/lychee) | repo `make check` (skill link resolution) | `mise use lychee` |
| [vhs](https://github.com/charmbracelet/vhs) | bootstrap (CLI demo GIFs) | `mise use vhs` |
| [ttyd](https://github.com/tsl0922/ttyd) | bootstrap (terminal recording) | `mise use ttyd` |

Other package managers (Homebrew, apt, go install) work fine — mise is what the examples use.

## Quality gates

Run `make check` for fast local feedback before committing. Run `make test` for the complete offline contract suite.

`make test` runs the executable repository validation suite through sequential
repository and skill/workflow concern suites. It reports the
failing concern and preserves a non-zero aggregate status. See
[`docs/adr/0009-modular-repository-test-suite.md`](docs/adr/0009-modular-repository-test-suite.md)
for the assertion map, alternatives, and rollback boundary. It fails with a
clear error if the configured test path is missing.

## Credits

- [Kun Chen](https://github.com/kunchen) — the [AXI](https://github.com/kunchen/axi) principles and repository, which shaped the ergonomic standards for agent-facing CLIs used throughout these skills
- [Matt Pocock](https://github.com/mattpocock) — whose [skills repository](https://github.com/mattpocock/skills) inspired the structure and progressive disclosure patterns used here

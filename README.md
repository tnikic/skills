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

Skills are discovered automatically. Run `/bootstrap` in any repo to align it to the standard project shape, or `/capture` to file a bug or idea.

## Dependencies

Some skills depend on external tools. Install with [mise](https://mise.jdx.dev/) (recommended) or your package manager of choice.

| Tool | Used by | Install (mise) |
|------|---------|----------------|
| [anvil](https://github.com/tnikic/anvil) | capture, triage, implement, to-tickets | `mise use go:github.com/tnikic/anvil` |
| [gitleaks](https://github.com/gitleaks/gitleaks) | capture (secrets stripping), bootstrap (check target) | `mise use gitleaks` |
| [lychee](https://github.com/lycheeverse/lychee) | repo `make check` (skill link resolution) | `mise use lychee` |
| [vhs](https://github.com/charmbracelet/vhs) | bootstrap (CLI demo GIFs) | `mise use vhs` |
| [ttyd](https://github.com/tsl0922/ttyd) | bootstrap (terminal recording) | `mise use ttyd` |
| [plow](https://github.com/tnikic/plow) | wayfinder (web search) | `mise use go:github.com/tnikic/plow` |

Other package managers (Homebrew, apt, go install) work fine — mise is what the examples use.

## Credits

- [Kun Chen](https://github.com/kunchen) — the [AXI](https://github.com/kunchen/axi) principles and repository, which shaped the ergonomic standards for agent-facing CLIs used throughout these skills
- [Matt Pocock](https://github.com/mattpocock) — whose [skills repository](https://github.com/mattpocock/skills) inspired the structure and progressive disclosure patterns used here

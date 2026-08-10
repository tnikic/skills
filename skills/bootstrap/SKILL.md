---
name: bootstrap
description: Align a repo to the standard project shape using language profiles. Run in any repo.
disable-model-invocation: true
---

# Bootstrap

Align a repo to the standard project shape. Re-runnable — fills gaps, never removes intentional content.

## Invocation

The user runs `/bootstrap` in a repo. No arguments — the agent detects the project language and applies the matching profile.

```
/bootstrap
```

---

## 1. Detect the project language

Check these signals in order:

| Signal | Language | Profile |
|--------|----------|---------|
| `go.mod` exists | Go | `profiles/go.md` |
| `Cargo.toml` exists | Rust | `profiles/rust.md` |
| None of the above | Unknown | `profiles/base.md` |

Load the matching profile. If `<project>/.agents/bootstrap.md` exists, load it as overrides.

---

## 2. Apply the profile

Read the profile to determine the command runner (Makefile / justfile / none) and targets. Generate each file.

### Command runner file

Create the command runner file with every target declared in the profile. Each target body runs the command specified in the profile's targets table.

Targets are ordered: `check` dependencies first, then `test`, `build`, `clean`, `help` last.

`help` is self-documenting — it lists every target with its description.

### Pre-commit hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/sh
set -e
make check
```

Replace `make check` with `just check` for justfile projects. Mark it executable.

If `.git/hooks/pre-commit` already exists and runs `make check` / `just check`, leave it alone.

### CI pipeline

Detect the CI platform:
- `.github/workflows/` exists → GitHub Actions
- `.gitlab-ci.yml` exists → GitLab CI
- Neither → GitHub Actions (create `.github/workflows/`)

Generate a pipeline that runs the profile's CI command. Research the latest action versions at generation time. Do not hardcode version numbers — fetch them from primary sources.

### README

Load `readme-template.md`. Generate a README following the template's section order, badge rules, and voice guidelines.

Detect the visual slot type:
- Project has a `main.go` in `cmd/` or root that compiles to a binary → CLI (GIF placeholder)
- Otherwise → web/lib (screenshot placeholder)

Leave the version badge slot empty unless the project version ≥ 0.1.0 (check `go.mod`, `Cargo.toml`, or `package.json`).

---

## 3. Re-run behavior

If the command runner file already exists, do not regenerate it from scratch. Instead:

1. Read the existing file
2. Compare against what the profile declares should exist
3. Add any missing targets at the end of the file, preserving existing content and ordering
4. Never remove or restructure existing targets — they were added intentionally

Same rule for the README: add missing sections after the last existing section. Never remove content.

If pre-commit hook or CI pipeline already exist in the expected shape, skip them.

---

## 4. Per-project overrides

If `<project>/.agents/bootstrap.md` exists, it overrides specific profile keys. For each override declared:

| Override | Effect |
|----------|--------|
| Tool version pin | Use the override version instead of researching latest |
| Tool disabled | Omit that tool from the generated targets |
| Extra target | Add a user-defined target to the command runner |

Merge overrides before running step 2. The profile is the base; the override file only changes what it explicitly declares.

---

## 5. Report

After generation, list every file created or updated:

```
Bootstrapped:
  ✓ Makefile (5 targets: check, test, lint, fmt, help)
  ✓ .git/hooks/pre-commit (new)
  ✓ .github/workflows/ci.yml (Go 1.24, golangci-lint latest)
  ✓ README.md (go profile, CLI visual slot)
```

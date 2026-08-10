---
name: capture
description: Capture bugs and ideas as properly-shaped tickets. User-invoked.
disable-model-invocation: true
---

# Capture

File a bug or idea into the ticket pipeline. Two modes — the agent detects which from what the user says.

## Invocation

The user describes what they want in natural language. The agent detects the mode, target repo, and any extra context.

```
"capture bug in owner/repo — the login page times out after 30s"
"capture idea on this repo — add dark mode support"
"capture bug — the CLI crashes when I pass --verbose"
```

## Mode detection

| User says | Mode | Body template |
|-----------|------|---------------|
| "bug," "crashes," "broken," "doesn't work," "error" | `bug` | 6-section forensic body |
| "idea," "feature," "would be nice," "suggest" | `idea` | 3-section lightweight body |

When ambiguous, ask: "Is this a bug report or a feature idea?"

## Target repo

Resolve the target repo from the user's words:

- `"for owner/repo"` → `owner/repo`
- `"on this repo"` or no repo mentioned → the current repo

If the target repo is not the current repo, create the issue there. `anvil issue create --repo <target>`.

---

## Bug body

Generate this exact Markdown body and post it as the issue:

```markdown
## What happened

<user's description of the failure>

## What was expected

<what should have happened instead>

## What I tried

- Last known working version: <ask user or note "unknown">
- <any workarounds the user mentioned>

## Steps to reproduce

1. <infer from user's description or ask>
2. <each step on its own line>

## Environment

- OS: <auto-detect: uname -s>
- Shell: <auto-detect: $SHELL>
- Tool version: <auto-detect the relevant binary version>

## Last command + error

```
<paste the last command and its output — ask the user or capture from session>
```
```

Auto-detect environment fields. Ask the user for anything you cannot determine from the session.

## Idea body

```markdown
## Idea

<user's description>

## Why it matters

<ask the user or note "not specified">

## Constraints

<ask the user or note "none">
```

---

## Sensitive data stripping

Run two layers before posting. If either layer redacts anything, show the cleaned body and ask the user to confirm.

### Pattern layer

Scan the body for these patterns. Replace matched values with `[REDACTED]`.

- `KEY=`, `SECRET=`, `TOKEN=`, `PASSWORD=` followed by any value
- `--token`, `--api-key`, `--secret` followed by any value
- `Bearer <value>`, `Authorization: <value>`
- Connection strings with embedded passwords (`://user:pass@`)
- `ghp_*`, `github_pat_*` (GitHub tokens)
- AWS key patterns (`AKIA*`, `ASIA*`)
- Private IPs (`10.x.x.x`, `192.168.x.x`, `172.16-31.x.x`)

### Agent judgment layer

After pattern stripping, read the full body and ask: "Does anything here still look sensitive?" Redact:

- Email addresses in error output
- Hostnames in stack traces that identify internal infrastructure
- Filesystem paths containing usernames (`/home/alice/` → `/home/[REDACTED]/`)

If nothing remains, skip the confirmation prompt and post.

---

## Labels

Apply these labels to the created issue:

- `triage:pending`
- `type:bug` (bug mode) or `type:enhancement` (idea mode)

No `source:` or other marker labels. Triage reads the body, not the source.

---

## Post

Create the issue on the target repo:

```
anvil issue create --repo <target> --title "<title>" --body "<body>" --label triage:pending --label type:bug
```

Use a descriptive title derived from the user's first sentence. Capitalize the first word, no period at the end.

### Label colors

After creation, fix the auto-created labels' colors. `anvil issue create --label` auto-creates labels that don't exist yet, but with a default color (`#333333`) instead of the taxonomy colors in [`label-taxonomy.md`](../../shared/label-taxonomy.md) and [`color-palette.md`](../../shared/color-palette.md). Run `anvil label update` with the correct scope and color:

```
anvil label update pending --scope triage --color 84a59d
anvil label update bug --scope type --color f28482
```

For idea mode, replace `bug` with `enhancement`. These commands are idempotent — if the label already has the right color, they succeed without change.

After posting, tell the user the issue number and URL.

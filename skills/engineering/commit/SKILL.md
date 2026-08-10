---
name: commit
description: Universal commit gate. Stage, safety-check, run quality and docs gates, craft a conventional-commits message, and commit. Use when the user asks to commit, or when a skill has produced changes that need committing.
---

# Commit

Universal choke point — every commit flows through here. Five steps, two hard blocks, one safety check.

## Intent detection

Read the conversation to determine what the user wants. No flags.

| User says | Behavior |
|-----------|----------|
| "commit" | Full flow: stage → safety → quality → docs → message → commit |
| "commit just <files>" | Skip auto-stage. Safety check on already-staged files |
| "commit with message '<msg>'" | Skip conventional-commits. Use the provided message |
| "amend" / "amend that commit" | Amend flow: gates still run, keep existing message |
| "amend and reword" | Amend flow: gates + regenerate message |

When another skill invokes `/commit` after producing changes, it uses the "commit" path.

---

## 1. Stage

Run `git add -A`. Skip if the user already staged files manually or specified specific files.

---

## 2. Safety check

Categorize every staged file into one of three buckets:

| Bucket | Files | Action |
|--------|-------|--------|
| **Agent-touched** | Created or modified during this session | Auto-commit |
| **Generated** | Output of a command the agent ran (sqlc, protoc, go generate) | Auto-commit |
| **Unknown** | Not touched by the agent, not from a generator | Prompt |

For unknown files, present them and ask:

```
⚠️  staging.md was not created during this session. Commit?

  [y] commit all    [n] skip unknown files    [d] review diff
```

If the user chooses `n`, unstage the unknown files and proceed. If `d`, show `git diff --cached` for those files and ask again.

---

## 3. Quality gate

Run the project's `check` target. Detect the command runner:

- `make check` (Makefile exists)
- `just check` (justfile exists)
- Skip if neither exists

Parse the output into a structured report:

```
✓ lint: passed
✓ fmt: passed
✗ typecheck: 2 errors in ./internal/auth/
```

If any target fails, block the commit. Present the report. Do not proceed.

If no command runner exists, skip the gate with a note: "No check target configured — run /bootstrap to add one."

---

## 4. Docs gate

Check whether the staged diff touches any doc file. Scan for:

- `README.md`, `README`
- `CONTRIBUTING.md`, `CONTRIBUTING`
- `CHANGELOG.md`, `CHANGELOG`
- Any file referenced in an existing README's link index

### No doc files in the diff

Skip the gate. Continue.

### Doc files in the diff

Read each doc file. Check whether the diff makes any section stale:

- A new feature without a README mention
- A changed API without an updated example
- A new dependency without a badge or setup instruction
- A version bump without a version badge

If docs are stale, auto-update them:

- Add missing sections after the last existing section
- Never remove or restructure existing content
- Follow the README template's voice rules

If auto-update succeeds, stage the updated doc files and continue.

If auto-update cannot resolve the gap, block the commit:

```
✗ Docs gate: CHANGELOG.md is stale
  The diff adds a new feature but CHANGELOG has no entry for it.
  Please update CHANGELOG.md and re-run /commit.
```

---

## 5. Message

Generate the commit message:

- **Normal commit** — invoke `/conventional-commits`. Present the message for approval. User can edit.
- **User provided a message** — use it as-is. Skip generation.
- **Amend** — present the existing commit message. User edits if needed.
- **Amend with reword** — invoke `/conventional-commits` anyway.

User must approve the final message before proceeding.

---

## 6. Commit

Run `git commit -m "<approved message>"`.

If amending: `git commit --amend -m "<message>"`.

Report the commit hash.

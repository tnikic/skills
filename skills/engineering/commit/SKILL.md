---
name: commit
description: Universal commit gate. Stage, safety-check, run quality and docs gates, craft a conventional-commits message, commit, and push. Use when the user asks to commit, or when a skill has produced changes that need committing.
---

# Commit

Universal choke point — every commit and push flows through here. The gate has two hard blocks and one safety check.

## Intent detection

Read the conversation to determine what the user wants. No flags.

| User says | Behavior |
|-----------|----------|
| "commit" | Full flow: stage → safety → quality → docs → message → commit → push |
| "commit just <files>" | Skip auto-stage. Safety check on already-staged files |
| "commit with message '<msg>'" | Skip conventional-commits. Use the provided message |
| "amend" / "amend that commit" | Amend flow: gates still run, keep existing message |
| "amend and reword" | Amend flow: gates + regenerate message |

When another skill invokes `/commit` after producing changes, it uses the "commit" path.
When another workflow supplies a requested footer such as `Closes #N`, preserve it
in the approved message and the resulting commit.

---

## 1. Stage

Run `git add -A`. Skip if the user already staged files manually or specified specific files.

*Completion criterion: every intended change is staged, or the explicitly
specified staged paths are ready for the safety check.*

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

*Completion criterion: every staged file is agent-touched, generated, or has an
explicit user decision.*

---

## 3. Quality gate

Run the project's `check` target. Detect the command runner and invoke it — see [`command-runner.md`](../../shared/command-runner.md) for the detection logic and standard targets.

Parse the output into a structured report:

```
✓ lint: passed
✓ fmt: passed
✗ typecheck: 2 errors in ./internal/auth/
```

If any target fails, block the commit. Present the report. Do not proceed.

If no command runner exists, skip the gate. The command-runner module will report this — relay its message.

*Completion criterion: `check` passes, or the command-runner limitation is
reported and the gate does not claim a green check.*

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

*Completion criterion: the staged documentation is fresh, or the commit is
blocked with the stale section identified.*

---

## 5. Message

Generate the commit message:

- **Normal commit** — invoke `/conventional-commits` in explicit **message-only mode**. The delegated skill analyzes the staged diff, runs only any checks still required by this gate, presents the message for approval, and returns approved message(s) plus any accepted split groups. It never stages or commits in this mode.
- **User provided a message** — use it as-is. Skip generation.
- **Amend** — present the existing commit message. User edits if needed.
- **Amend with reword** — invoke `/conventional-commits` in explicit
  **amend-reword mode**. The delegated skill analyzes `HEAD`'s existing commit
  rather than requiring staged changes.

For generated messages, the delegated skill owns presentation and approval. Once
it returns approved message(s), proceed without asking for a second approval.
User-provided and existing amend messages are already approved by the intent
branch above.

*Completion criterion: approved message(s) and any split groups are ready for
the commit step.*

---

## 6. Commit

Run `git commit -m "<approved message>"`. If the approved plan splits the diff, isolate each accepted group in the staging area before running its commit.

If amending: `git commit --amend -m "<message>"`.

Report the commit hash.

*Completion criterion: the approved local commit or commits exist and their
hashes are reported.*

## 7. Push

After the local commit succeeds, run `git push -u origin HEAD`. If the push
fails, report the failure and stop without claiming that the commit was
published. Do not delegate pushing back to the workflow that requested the
commit.

*Completion criterion: the approved commit exists locally and has been pushed,
or the push failure is reported without claiming publication.*

---
name: resolving-merge-conflicts
description: "Resolve an in-progress git merge or rebase by tracing each side's intent, running the repository checks, and finishing through the commit gate."
---

# Resolving Merge Conflicts

Resolve conflicts by recovering intent from the repository, not by choosing a side mechanically. Preserve the merge or rebase operation unless the user explicitly asks to abandon it.

## 1. See the current state

Confirm that a merge or rebase is in progress. Read the status, recent history, conflict list, and each conflicted file. Identify the current operation and its expected completion command.

*Completion: every conflicted path and the active merge or rebase state are known.*

## 2. Find the primary sources

For each hunk, inspect the commits, issue or spec, PR discussion, and surrounding code that explain both sides. Follow the stated goal of the merge or rebase. If the intent cannot be established, stop that hunk and report the ambiguity instead of inventing behavior.

*Completion: every hunk has a documented reason for the chosen resolution or is explicitly reported as unresolved.*

## 3. Resolve each hunk

Preserve both intents where they are compatible. Where they conflict, keep the behavior that matches the operation's stated goal and record the trade-off. Resolve all intended files, remove conflict markers, and inspect the resulting diff. Do not use `git merge --abort` or `git rebase --abort` as a shortcut.

*Completion: no intended conflict remains, no conflict marker remains, and the diff contains no behavior invented without a source.*

## 4. Run the checks

Read the shared [`command-runner`](../../shared/command-runner.md) reference and run the repository's configured checks, typically static analysis, type checking, tests, and formatting. Fix failures caused by the resolution. If a check cannot run, report the exact blocker.

*Completion: every applicable check passes, or each unavailable check has a stated reason and impact.*

## 5. Finish safely

Stage the resolved files and verify the staged diff. Route the merge or rebase commit through `/commit`; do not run `git commit` directly. If the commit gate is not available in the current session, leave the operation staged and report the exact command the user must run. After committing, verify that the merge or rebase is no longer in progress and report the resulting commit.

*Completion: the operation is complete through the commit gate, or the staged operation is ready for that gate with the limitation reported.*

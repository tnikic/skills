---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save one uniquely named file in the temporary directory of the user's OS - not the current workspace. Use the OS secure temporary-file API (the `mktemp` equivalent) with an `agent-handoff-XXXXXX.md` template and return its absolute path when done.

Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

*Completion criterion: the handoff file exists in the OS temporary directory, is
readable, contains the suggested skills section, and its absolute path has been
reported to the user.*

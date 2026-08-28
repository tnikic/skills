---
name: research
description: Investigate a question against primary sources, save cited findings in the stable per-user XDG cache, and return issue-backed results to their owner. Use when the user wants documentation, API, or implementation facts researched.
---

# Research

Investigate a question against the sources that own the answer, then leave a
concise, cited artifact another agent can use without repeating the work.
Identify the owner before gathering evidence; it receives the result and
controls the next continuation.

## 1. Frame the question and owner

State the question, the decision it informs, and the boundaries of the
research. Identify the issue, workflow, or artifact that requested the
research. Read `docs/CONTEXT.md` and relevant ADRs when the question concerns
this repository. If the question is broad, choose a reasonable scope and state
it rather than blocking on clarification.

*Completion: the research question, scope, and owner are written in one
paragraph.*

## 2. Gather primary sources

Use official documentation, source code, standards, specifications, or first-party APIs. Follow each important claim to the source that owns it. Prefer the repository's pinned dependency versions and local configuration over generic examples.

*Completion: every material claim has a primary source or is marked unresolved.*

## 3. Delegate the reading

Dispatch a `researcher` subagent for the normal research path using the shared [`subagent-dispatch`](../../shared/subagent-dispatch.md) pattern. Give it the question, scope, source requirements, intended cache path, owner, and a word limit. The researcher must return structured findings and must not invoke `research` recursively. If it writes scratch notes, keep them in OS temp outside the repository and remove them after synthesis. Investigate directly only when the subagent facility is unavailable or the answer depends on context already held in the current conversation; report that exception.

*Completion: the researcher has returned structured findings, or an explicit direct-investigation exception was recorded with the same source and evidence requirements applied.*

## 4. Write the findings to the research cache

Write one final Markdown file at
`${XDG_CACHE_HOME:-$HOME/.cache}/skills/research/<topic-slug>.md`. Create the
parent directory if needed. This stable per-user XDG cache path is the
canonical record; OS temp is scratch only, and no canonical research file goes
under the project path. Include the question, findings, implications for the
decision, unresolved gaps, and a source link beside each material claim. Keep
secrets and private data out of the artifact. The main agent owns this final
file; do not leave subagent scratch notes as a second source of truth.

*Completion: one readable Markdown artifact exists at the stable XDG cache path
and contains no uncited material claim presented as fact.*

## 5. Return the result to the owner

Read the artifact from disk. Check that each source link resolves or is an
intentional local pointer, that the findings answer the original question, and
that the file is not a duplicate of an existing note. When the owner is an
issue record, append useful findings and the cache path to that record in
developer-facing language through the matching forge skill. Preserve citation
and redaction guarantees; do not put internal routing procedure in the record.

*Completion: the artifact was reread, and an issue-backed owner record contains
the useful cited findings or the owner has received the result in the current
interaction.*

## 6. Continue the owner

At the specialist-result boundary, read the shared
[`continuation`](../../shared/continuation.md) reference and return the owner's
complete continuation set in the live interaction. Report the path, main
conclusion, unresolved uncertainty, and the owner's ready-now and later
actions. Do not choose a generic research route in place of the owner's route.

*Completion: the owner continuation is explicit, exhaustive, and separate from
the developer-facing record.*

---
name: research
description: Investigate a question against primary sources and capture cited findings in the repository. Use when the user wants documentation, API, or implementation facts researched.
---

# Research

Investigate a question against the sources that own the answer, then leave a concise, cited artifact another agent can use without repeating the work.

## 1. Frame the question

State the question, the decision it informs, and the boundaries of the research. Read `docs/CONTEXT.md` and relevant ADRs when the question concerns this repository. If the question is broad, choose a reasonable scope and state it rather than blocking on clarification.

*Completion: the research question and scope are written in one paragraph.*

## 2. Gather primary sources

Use official documentation, source code, standards, specifications, or first-party APIs. Follow each important claim to the source that owns it. Prefer the repository's pinned dependency versions and local configuration over generic examples.

*Completion: every material claim has a primary source or is marked unresolved.*

## 3. Delegate the reading

Dispatch a `researcher` subagent for the normal research path using the shared [`subagent-dispatch`](../../shared/subagent-dispatch.md) pattern. Give it the question, scope, source requirements, intended final path, and a word limit. The researcher must return structured findings and must not invoke `research` recursively. If it writes scratch notes, keep them outside the repository and remove them after synthesis. Investigate directly only when the subagent facility is unavailable or the answer depends on context already held in the current conversation; report that exception.

*Completion: the researcher has returned structured findings, or an explicit direct-investigation exception was recorded with the same source and evidence requirements applied.*

## 4. Write the findings

Write one final Markdown file where the repository keeps research notes. If no convention exists, use `docs/research/<topic-slug>.md`. Include the question, findings, implications for the decision, unresolved gaps, and a source link beside each material claim. Keep secrets and private data out of the artifact. The main agent owns this final file; do not leave subagent scratch notes as a second source of truth.

*Completion: one readable Markdown artifact exists at the reported path and contains no uncited material claim presented as fact.*

## 5. Verify and report

Read the artifact from disk. Check that each source link resolves or is an intentional local pointer, that the findings answer the original question, and that the file is not a duplicate of an existing note. Report the path, the main conclusion, and any unresolved uncertainty.

*Completion: the artifact was reread and its path, conclusion, citations, and limitations are reported.*

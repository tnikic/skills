# Ticket-Focused PR/MR Template

Render one body for each implementation ticket. Preserve the ticket's meaning;
do not invent acceptance results or turn a spec-wide summary into a ticket
summary.

## Change scope

<!-- State the ticket's user-visible change and the implementation boundaries. -->

## Notable decisions

<!-- Record decisions a reviewer needs to understand this ticket. -->

## Validation

<!-- List the checks run and their outcomes. -->

## Acceptance results

<!-- Mirror every ticket criterion and mark its actual result. -->

- [ ] <!-- Criterion from the implementation ticket -->

## Spec context (optional)

<!-- Link the parent spec and summarize only the context relevant to this ticket. -->

## Stack position

<!-- State this ticket's position and target branch, for example 2/4 -> ticket-1. -->

## Dependency context

<!-- State the predecessor, external blocker, or "None". -->

## Related records

<!-- Link the ticket, spec, and other relevant records. -->

- Related: #N

Use `Related` or `Refs` while this publication targets an intermediate stack
branch. Only the final publication whose change reaches the default branch may
carry the appropriate `Closes #N` references for the ticket and, when
applicable, its parent spec.

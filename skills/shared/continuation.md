# Continuation Contract

This reference defines the internal result a workflow returns at its boundary.
It is for the live agent interaction, not for public issue prose. A workflow
reports one **continuation set**: the current state and the actions that follow
from it.

## Continuation Set

Every continuation set contains these fields:

- **Current state** - the workflow's state at the boundary:
  - `ready` means at least one action can start now.
  - `blocked` means a dependency prevents every action and the dependency is
    an issue or task.
  - `pending` means the workflow is waiting for a human or external result,
    including when that result is listed as a dependency.
  - `complete` means its declared result is achieved.
  Classify a human or external wait as `pending`, not `blocked`.
- **Ready now** - every exact action that can be taken immediately. Name the
  skill, command, or human action and state the result it should produce. If
  more than one independent action is ready, list each one; do not turn
  independent work into an implied sequence.
- **Later** - actions that are not ready yet, with the condition that makes
  each one actionable. Keep them separate from ready-now actions so follow-up
  work cannot be mistaken for the current route.
- **Dependencies** - prerequisites that explain why an action is blocked or
  later. Use native tracker relationships for genuine issue dependencies; do
  not encode blockers only in prose.
- **Deliberate stop** - an explicit intentional stopping point when no further
  action is being requested. State why the workflow stops and distinguish it
  from `blocked`, `pending`, or unfinished work.

The continuation set is exhaustive at the workflow boundary: it accounts for
the current state, all actions that are ready now, all known later actions, all
dependencies, and any deliberate stop. A result that only says "continue" or
names the skill that just ran is not a continuation set.

Every field is present even when it has no entries. Use `None` for an empty
ready-now list, later list, dependency list, or deliberate stop.

## Fan-Out

When a workflow exposes multiple independent next actions, return them as
separate ready-now or later entries. Each entry names its own action, owner or responsible party when relevant, expected result, and dependency condition.
The set may contain one actionable result now and non-blocking later work; the
later work must not delay the ready action.

## Route Selection

Use the shortest route that preserves the required issue record:

- **One-ticket shortcut** - when the settled implementation landscape contains
  exactly one implementation ticket.
  Route to `/to-tickets` to create that issue record.
  Then expose `/implement` as the next continuation.
  The issue record exists before implementation begins.
- **Multi-ticket route** - when implementation needs multiple tickets or a
  richer requirements artifact, route to `/to-spec` to publish one
  specification, then `/to-tickets` to plan its implementation tickets, then
  `/implement` for those tickets.

This reference defines when each route is selected and the order of its
continuations. The destination skills own their publication, ticket, and
implementation procedures; consumers do not duplicate those rules here.

## Internal And Public Records

The exact continuation set belongs in the agent interaction. It may name the next skill and the condition for reaching it, but it does not belong in an issue body or comment.

Developer-facing issue records describe the work, decisions, evidence,
dependencies, and outcomes in ordinary project language. Native tracker
metadata such as labels, parent-child relationships, assignees, and blocking
edges remains available for coordination. Metadata and public prose may
describe the same project fact, but neither should expose internal routing
procedure.

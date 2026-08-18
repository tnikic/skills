# Pull Request Delivery Contracts

These contracts are shared by implementation and forge skills. They keep the
workflow provider-neutral while leaving command syntax to the `github` and
`gitlab` skills.

This is the target contract for PR-based delivery. The dependent workflow and
forge-adapter tickets consume it; this document does not reimplement their
operations.

## Spec Slugs

A spec slug is the spec name converted to lowercase kebab case. It is the
single naming source for the branch description and the PR title, so both
identify the same work.

## Branch Names

Agent-created branches use the Conventional Branch `<type>/<description>`
form. The type is mapped from the ticket's dominant commit type, with `chore`
as the fallback and `refactor` available as a team extension.

Per-ticket delivery uses:

```text
<type>/<ticket-number>-<spec-slug>
```

Example: `feat/55-pr-delivery-contracts`.

An explicitly combined spec uses one branch for all of its tickets:

```text
<type>/<spec-slug>
```

Example: `feat/pr-delivery-contracts`.

Merge-order numbers never appear in branch names. They belong only in PR
titles, where they can be renumbered without changing the branch identity.

## PR Titles

PR titles use the provisional merge-position form:

```text
[<spec-slug> <n>/<N>] <summary>
```

`n` is the provisional merge position and `N` is the stable ticket count for
the spec. The fleet manager may normalize positions after parallel work
settles. A combined PR still uses the spec slug and the same title form.

## Review Impact

Review impact is advisory triage, not priority and not a merge gate. The
allowed values are:

| Value | Use |
|-------|-----|
| `critical` | Security, authentication, or high-blast-radius changes |
| `high` | Broad or important changes |
| `normal` | The default for work without a declared impact |
| `low` | Trivial, narrow changes |

Specs may declare one value per ticket. When no value is declared,
`implement` applies `impact:normal` to the PR. Impact labels never authorize,
block, or replace human review or required CI.

## Delivery Lifecycle

`implement` keeps the ticket open and assigned while it creates the PR. The PR
body projects the ticket using [`pr-template.md`](pr-template.md) and contains
the `Closes #N` relationship. The human reviewer owns approval and squash
merge; the ticket closes only when that PR merges to the default branch.

Issue-closing metadata belongs in the PR body, never in a commit message.

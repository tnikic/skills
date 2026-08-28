# Sequential Per-Spec Stacks

Each implementation ticket produces one branch and one pull request or merge request, while tickets in the same spec advance sequentially through one linear stack. A ready predecessor branch can support downstream implementation before merge; separate specs may run in parallel, but non-linear or external dependencies remain blockers rather than being silently flattened.

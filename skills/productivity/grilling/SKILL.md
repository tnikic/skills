---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea — a discussion that ends in a plan. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

## Ground rules

Grilling is a discussion that ends in a plan, not in code. While it runs, the only files you write are:

- `docs/CONTEXT.md` and `docs/adr/` — domain-modeling's docs, captured as decisions land
- throwaway prototypes, built under `/prototype`'s own rules

Everything else — source, tests, config — is written by `/implement`, after the user confirms shared understanding.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled — the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Each question should be formatted like so:

```
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>
```

Each round the user answers reshapes the tree — settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it — don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report — ask the rest of the frontier now. The _decisions_ are the user's — put each to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. When the user confirms you have reached a shared understanding, **end with the plan**: a short summary of the decisions made and the threads still open, plus the next step — `/to-spec` to write it up, or `/implement` to build it. Grilling ends at the plan; the build is a separate invocation.

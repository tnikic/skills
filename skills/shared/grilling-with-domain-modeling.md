# Grilling with Domain Modeling

When a decision needs both grilling (stress-testing) and glossary updates, interleave them:

- Grill a batch of questions
- Update `docs/CONTEXT.md` as domain terms crystallize
- Grill the next batch

This keeps the domain model current as decisions land, rather than trying to reconstruct terms after the session. Callers that need this pairing point here instead of restating the invocation.

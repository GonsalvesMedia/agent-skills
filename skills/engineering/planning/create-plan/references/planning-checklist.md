# Planning Checklist

Use after drafting. Machine validation (`scripts/validate-plan.py`) is necessary but not sufficient.

## Premise / scope

- [ ] User-visible outcome is named (symptom or prevention goal), not only an architectural impulse
- [ ] Already-shipped mitigations (detection, recovery, gates) are acknowledged when relevant
- [ ] Prevention vs outcome is explicit when both could apply
- [ ] Scope is the smallest set that buys the chosen outcome
- [ ] Simpler alternative is stated and rejected with a reason
- [ ] Appetite / time budget is set

Yellow lights (any one: trim; two: stop and shrink):

- New abstraction where a small fix meets the chosen goal
- Single incident cited without frequency/severity evidence when building a large system
- Review loops that only add scope without challenging premise
- Documentation footprint driving plan size
- "Prevention" as motivation while recovery already ships and prevention was never chosen

## Code-first

- [ ] Relevant current files were read (not summarized from memory)
- [ ] Recent history on touched paths was checked
- [ ] Competing in-progress plans touching the same area were checked
- [ ] Field names, types, and paths match source
- [ ] External research limited to decisions that depend on current outside behavior

## Readiness

- [ ] Draft: blocking questions marked, each with recommended answer + why
- [ ] Implementation-ready: open questions = 0; no A/B menus; every decision concrete
- [ ] Confidence scorecard filled (no placeholder scores); reversibility and blast radius stated
- [ ] Risks/pre-mortem and rollback present for non-trivial work
- [ ] Success metrics defined for non-trivial work
- [ ] File/contract impact table is specific
- [ ] Phased implementation with exit criteria
- [ ] Large plans are sliced into independently buildable and verifiable increments
- [ ] Verification items are testable
- [ ] Documentation follow-up listed when durable knowledge changed
- [ ] No TODO/TBD placeholder tokens

## Mode coverage

| Section | Quick | Standard | Architecture |
|---------|-------|----------|--------------|
| Problem + motivation | Brief | Full | Full |
| Why not simpler | Brief | Full | Full |
| Goal + mental model | One line | Full | Full + exec summary |
| Non-goals | One line | Required | Required |
| Assumptions | — | Required | Required |
| Implementation phases | Flat list | Phased | Phased + timeline |
| Files/contracts | Key only | Full | Full |
| Risk + pre-mortem | — | Top risks | Full |
| Rollback | — | Brief | Full |
| Success metrics | — | Required | Required |
| Confidence scorecard | Required | Required | Required |
| Deep notes | — | Optional | Required |
| Verification | Short | Full | Full + automated |
| Architecture drift | — | If applicable | Required when shared architecture moves |

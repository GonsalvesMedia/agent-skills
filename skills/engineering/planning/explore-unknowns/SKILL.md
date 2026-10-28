---
name: explore-unknowns
description: Map a vague or unfamiliar task before committing to a plan. Use when the user explicitly asks to explore unknowns, clarify an ambiguous request, understand an unfamiliar codebase or reference implementation, capture plan deviations, or build shared understanding before planning or implementation.
---

# Explore Unknowns

Run a four-quadrant discovery conversation. The deliverable is a shared map of what is settled, what must be decided, what tacit context needs eliciting, and what risks remain—not an implementation.

## Workflow

Move through one quadrant at a time. Surface any finding immediately if it materially affects a decision; stage order must not hide relevant information.

1. **Known knowns** — inspect the available territory: user request, repository, current behavior, existing plans, and relevant evidence. Present only claims grounded in source or label them as assumptions.
2. **Known unknowns** — list the decision-changing questions. Resolve each through evidence, a narrowly targeted user question, or an explicit recommended assumption.
3. **Unknown knowns** — help the user react to concrete options, examples, mockups, comparisons, or decision tables to uncover taste and tacit constraints. Do not ask them to articulate what a concrete artifact could reveal.
4. **Unknown unknowns** — sweep for adjacent systems, failure modes, permissions, data lifecycle, scale, rollback, external dependencies, and hidden stakeholders that could invalidate the work.
5. **Hand over the map** — provide the four quadrants, decisions made, open questions with owners, evidence, assumptions, risks, and the recommended next action: plan, prototype (`$prototype`, if installed), primary-source research, or implementation.

## Rules

- Stop for user input when a choice materially changes correctness, safety, reversibility, or product intent. Otherwise state a reasonable assumption and continue.
- Nothing is marked resolved unless the user saw the evidence or decision.
- Cite real files and observed behavior; do not fabricate specific facts.
- Keep artifacts proportional. Use a table, sketch, or prototype (`$prototype`, if installed) only when it makes a hidden choice easier to react to. Gather material facts from primary sources or the environment rather than asking the user to supply them.
- Do not implement as part of this skill. Hand the map to `$create-plan` or the user’s next chosen workflow.

## Done

The map is complete when all four quadrants are visible to the user and the next action is explicit.

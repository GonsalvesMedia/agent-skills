# Plan Template

Structural skeleton. Adapt section names to local conventions when the repo already has a template; keep the substance below. Delete sections that do not apply; never leave placeholder tokens.

---

## Optional frontmatter

Use only fields the repository already uses. Do not invent project-specific category enums.

```yaml
---
status: draft          # or local equivalents: planning | approved | active | done | archived
priority: medium       # if the repo uses priority
tags: [tag1, tag2]
---
```

---

## Header

```markdown
# [Feature Name] Plan

> **Created**: YYYY-MM-DD
> **Mode**: quick | standard | architecture
> **Motivation**: One sentence on why this work matters now.
```

---

## Problem / Motivation

Current state and what is wrong or missing. State explicitly: **why not [obvious simpler alternative]?**

Name the **user-visible outcome**. If the work is prevention rather than closing an unmitigated hole, say so and note any already-shipped detection/recovery mitigations.

---

## Goal

What success looks like. Include mental model (before/after) when the user-facing model changes.

---

## Non-goals / Out of Scope

What this plan intentionally does not do.

---

## Assumptions + Constraints

Assumptions that would invalidate the plan if wrong.

---

## Confidence Scorecard

| Axis | Score (1–10) | Reasoning |
|------|-------------|-----------|
| Technical (do we know *how* to build it?) | N | ... |
| Requirement (do we know *what* to build?) | N | ... |
| Impact (will this solve the problem?) | N | ... |

**Reversibility**: Feature-flagged / reversible migration / irreversible — explain
**Blast radius**: Local / scoped / broad — explain worst case
**Open questions**: N

### Open Questions

_Draft plans may list blocking questions. Each must include a recommended answer. Implementation-ready plans must have zero unresolved items._

- [x] Example resolved question — **Recommended**: X. **Why**: Y. (Confirmed.)

---

## Risk + Pre-mortem

_Assume it is months later and this failed. What went wrong?_

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| ... | Low/Med/High | Low/Med/High | ... |

**Rollback plan**: how to undo or disable.

---

## Success Metrics

How we know it worked after shipping (behavior, error rates, time-to-signal).

---

## Data / Contracts

- No schema or API contract changes? Say so.
- Changes? Show exact shapes, migration/compat strategy, and consumers.

---

## Implementation Plan

Phased when non-trivial. Prefer independently shippable phases.

### Phase N — Name

- Goal, tasks, deliverable
- Exact interfaces/types verified against source
- Exit criteria

---

## Files / Contract Impacts

| Path | Change |
|------|--------|
| `path/to/file` | Specific change: what becomes what |

Rule: "Update X" is not enough.

---

## Verification

Numbered, testable outcomes (automated and/or manual). Not "X works correctly."

1. ...
2. ...

---

## Deep Implementation Notes (architecture / complex standard)

Field-name maps across boundaries, before/after snippets with real types, state/cache notes, line references.

---

## Architecture Drift (when applicable)

- Alignment with existing architecture docs
- Updates required to those docs
- Disagreements resolved and chosen path

---

## Documentation Follow-up (when warranted)

Durable docs to update after implementation (ADRs, runbooks, AGENTS.md, architecture notes). Omit when nothing durable changes.

Document the why, invariants, and pointers to the canonical implementation—not a roster of current files, constants, or command matrices that code already owns.

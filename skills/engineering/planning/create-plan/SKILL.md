---
name: create-plan
description: "Create a repository-aware implementation plan, PRD, technical spec, or roadmap item. Use when the user asks to plan a feature, write a PRD or spec, draft a roadmap plan, or produce an implementation-ready feature plan. Discovers local plan conventions; supports quick, standard, and architecture depth; code-first planning with premise/scope discipline. Not for implementing an already-approved plan."
---

# Create Plan

Plan before implementation. Discover this repository's conventions; do not assume plan folder names, package managers, frameworks, master-plan paths, or documentation layouts.

## Depth modes

| Mode | Trigger | Skip |
|------|---------|------|
| **Quick** | "quick plan", rough spec, fewer than ~5 files | External research, deep implementation notes, full pre-mortem |
| **Standard** | Default feature work | Nothing material |
| **Architecture** | New system, cross-cutting, multi-phase | Nothing — add executive summary and ADR-style alternatives |

Default to **Standard** when unspecified.

## Workflow

1. **Calibrate depth** from the request. Honor explicit user constraints ("skip research", scoped draft).
2. **Discover conventions** — inspect `AGENTS.md`, `CLAUDE.md`, existing plan folders, status/frontmatter patterns, and naming. Follow local lifecycle if present; otherwise write where the user directs or where sibling plans already live. See [references/plan-lifecycle.md](references/plan-lifecycle.md).
3. **Search relevant active learnings** when compound-engineering artifacts or project learnings exist (status `active`; treat `stale` as caution-only). Use them to inform constraints and alternatives; do not force capture or promotion from planning. Note optional compound follow-up (`$capture-learning`, `$refresh-learnings`, `$compound-workflow`, if installed) without embedding those workflows here.
4. **Product framing** — name the user-visible outcome; why not the simpler alternative; mental model before/after; appetite (time budget); non-goals. If product direction is ambiguous, ask one targeted question before research. If an important design question cannot be settled from prose or source, recommend a prototype (`$prototype`, if installed) before finalizing the plan.
5. **Premise / scope discipline** — distinguish prevention from already-shipped mitigation; prefer the smallest scope that buys the chosen outcome. See [references/planning-checklist.md](references/planning-checklist.md).
6. **Code first** — read every file that will change, related contracts/types, recent `git log` on those paths, and competing in-progress plans. Do not plan from summaries alone.
7. **External research only where material** — current library/API behavior that changes a decision; primary docs preferred.
8. **Reconcile architecture drift** — if the repo has a master/architecture plan or ADR set, challenge stale assumptions and record needed updates in the plan. When domain language is ambiguous, resolve terminology against existing project docs and record only durable decisions; do not invent mandatory filesystem moves or a required glossary format.
9. **Write the plan** using [references/plan-template.md](references/plan-template.md). Match mode-required sections.
10. **Validate** with `scripts/validate-plan.py <path-to-plan.md>`, then self-review against [references/planning-checklist.md](references/planning-checklist.md).
11. **Stop after planning.** Do not implement inside this skill.

## Decision rules

- **Draft**: may retain clearly marked blocking questions; each must include a recommended answer and why.
- **Implementation-ready**: concrete decisions only (no A/B menus), open questions = 0, reversibility and blast radius stated, top risks named with mitigations.
- Field names, types, and paths in the plan must match source. Vague "update X" file rows are insufficient.
- Include confidence scorecard, risks/pre-mortem (standard+), rollback, success metrics, exact file/contract impacts, phased implementation, verification, and durable documentation follow-up when warranted.

## Output

Report the exact plan path, depth mode used, validation exit status, and whether the plan is draft or implementation-ready.

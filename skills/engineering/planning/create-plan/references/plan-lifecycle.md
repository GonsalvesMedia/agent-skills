# Plan Lifecycle

Treat lifecycle as a **repository-convention-aware pattern**, not a forced directory layout.

## Discover local conventions first

Before creating or moving any plan file:

1. Search for existing plan/spec/roadmap folders and status schemes (`status:` frontmatter, `plan/planning/`, `roadmap/`, `docs/plans/`, issue trackers, etc.).
2. Read `AGENTS.md` / `CLAUDE.md` / project docs for naming and placement rules.
3. Match sibling plans' naming (e.g. `UPPER_SNAKE_CASE_PLAN.md`, kebab-case, dated prefixes).
4. If multiple conventions exist, prefer the one used by the nearest related plans and state which you followed.

## Conceptual states

Use these states conceptually even when the repo encodes them differently (folders vs frontmatter vs both):

| State | Meaning |
|-------|---------|
| Planning / draft | Discovery in progress; blocking questions may remain |
| Approved / ready | Implementation-ready; no blocking questions; concrete decisions |
| Active / in progress | Currently being executed |
| Awaiting approval | Implemented and verified; waiting for human signoff |
| Done | Accepted complete |
| Archived | Superseded, abandoned, or retained for history |

## Transition rules (when conventions exist)

- Update the **existing** plan in place during question close-out; avoid near-duplicate drafts.
- Keep one active plan document per effort when the repo uses an "active" slot or status.
- Prefer move/archive over delete when retiring a plan.
- If the repo has no lifecycle folders or status fields, write a single durable plan at the user-specified or discovered location and mark draft vs ready clearly in the document body.

## Architecture-drift pattern (convention-aware)

- If a master plan, architecture doc, or ADR set exists, treat it as an anchor to reconcile—not as unchallengeable scripture.
- When the request changes shared architecture, record needed updates in an `Architecture Drift` (or equivalent) section of the plan.
- Update the architecture baseline only when local conventions expect it and confidence is high enough; otherwise leave explicit follow-up items.
- Do not invent a master-plan file or force folder moves that the repository does not use.

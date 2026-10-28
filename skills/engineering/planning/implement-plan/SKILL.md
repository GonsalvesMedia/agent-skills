---
name: implement-plan
description: "Execute an approved implementation plan phase by phase with continuous progress until stop conditions. Use only when the user asks to implement an approved plan, build a named plan, or execute a plan they identify. Not for small unplanned direct work, exploratory fixes without a plan, or creating a new plan."
---

# Implement Plan

Execute a selected approved plan as a continuous loop. Do not turn small unplanned direct work into a planning blocker—decline this skill when the user wants a quick fix without a plan.

## Select the plan

1. If the user names or tags a plan, use that plan.
2. If the repository uses a plan lifecycle (folders or status fields), verify the selected plan is **approved** / ready before starting.
3. If multiple approved candidates exist and the user did not choose, **ask which plan** — never silently pick the oldest.
4. If no plan exists and the user asked to implement a plan, stop and say planning is required first. If they asked for unplanned direct work, do not invoke planning as a gate.

## Read first

- The selected plan in full (non-goals, risks, blind spots, verification — not only the implementation section)
- [references/execution-lifecycle.md](references/execution-lifecycle.md)
- [references/verification-strategy.md](references/verification-strategy.md)
- Relevant current source for every file the plan names

## Preflight

1. Inspect workspace hygiene with path-aware status; preserve unrelated workstreams.
2. Spot-check plan assumptions (paths, exports, types, behaviors) against current source.
3. Check recent history on targeted files for renames/refactors that invalidate the plan.
4. Reconcile stale plan steps and material architecture drift **before** coding; update plan docs when local lifecycle conventions exist.
5. Discover validation commands from the repository (`package.json`, `Makefile`, `AGENTS.md`, CI config) — do not assume a package manager or script names.

## Escalation — STOP vs decide

**STOP and surface:**

- Baseline checks already broken before your edits (when a baseline check is defined and runnable)
- Named path missing or identifier/signature mismatch vs the plan
- Load-bearing assumption fails verification
- Literal plan execution would break working behavior
- Unrelated substantial bug found mid-flight (note it; do not expand scope)
- A failing behavior cannot be explained with a focused, red-capable signal — hand off to a focused debugging workflow (`$diagnose-bugs`, if installed) before speculative fixes
- User contradicted the plan after it was written
- Destructive operations (delete data, reset, drop, force-push) appear necessary

**Decide and proceed:** naming, formatting, import order, exact placement within a stated region, obvious refactors of lines already being touched.

## Execution loop

While the next phase or titled sub-step is actionable:

1. Reconcile the step against current code (and architecture anchors if the repo has them).
2. Read each file fully before editing; prefer small scoped edits; do not invent scope.
3. Implement the durable solution for the current phase — continue without waiting for a nudge when the next step is defined and actionable.
4. Run the narrowest repository-discovered validation for the change; scale up for broad/risky phases per [references/verification-strategy.md](references/verification-strategy.md).
5. Update plan status / lifecycle / next-action **only when those conventions exist**.
6. For long or multi-phase work, take periodic maintenance checkpoints: reconcile the plan with current code, remove temporary layers, re-check priorities, and run a focused self-review before drift accumulates.
7. Proceed to the next phase unless a stop condition applies.

## Finish

1. Verify each acceptance criterion individually; classify unperformed manual checks explicitly.
2. Self-review the **path-scoped** diff; fix only issues introduced by this workstream.
3. Apply documentation follow-ups the plan requires when still warranted.
4. **Learning assessment** — when compound-engineering is in play or material reusable knowledge emerged, assess candidates for `$capture-learning` (create/update/supersede/skip) and note any stale guidance that warrants `$refresh-learnings` (both if installed). Do not write learnings routinely from this skill; do not duplicate capture/refresh workflows here.
5. Never commit, push, deploy, migrate, or destructively mutate without explicit authorization.
6. Report: files changed; checks run and results; acceptance criteria status; manual checks remaining; risks; learning assessment decision; exact plan path.

Delegated adversarial review is optional and only when the user asks — recommend `$use-codex` or `$use-cursor` advisory workflows if those skills are available; do not require them. Do not automatically fan out external models.

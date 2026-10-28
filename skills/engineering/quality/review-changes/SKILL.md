---
name: review-changes
description: "Review code, plans/specs, skills, or uncommitted changes, or generate a review prompt for another agent. Use when the user asks to review changes, sanity-check work, review a plan or skill, prepare for commit review, or create a review prompt. Modes: review (default, read-only), fix (only when explicitly asked to change findings), prompt-only. Does not auto-edit in a generic review."
---

# Review Changes

Review with premise scrutiny first, then coherence. Default mode is read-only.

## Modes

| Mode | When | Behavior |
|------|------|----------|
| **review** (default) | "review", "sanity check", unspecified | Read-only findings; **do not edit files** |
| **fix** | User explicitly asks to fix/resolve findings | Change only what the findings require; preserve unrelated work |
| **prompt-only** | "generate review prompt", handoff to another agent | Output one copy-pasteable review prompt; do not edit |

If mode is ambiguous and the user might want edits, ask once — default remains **review**.

## Workflow

1. **Determine scope before gathering diffs.** Use conversation context or ask when multiple workstreams are dirty. Prefer path-scoped git:

   ```bash
   git status --short -- <paths>
   git diff --name-status HEAD -- <paths>
   git log --oneline -15 -- <paths>
   ```

   Preserve unrelated changes. Bare full-tree diffs are only for discovering workstream boundaries, not for feeding an unfiltered review.

2. **Load local context** that applies: `AGENTS.md`, relevant plans/specs in scope, architecture notes, fragile-area docs if the repo has them.

3. **Categorize** targets: implementation, tests, plans/specs, skills, docs, config/deps.

4. **Premise before coherence** — verdict first line of the report:

   `Premise: justified | over-scoped | under-scoped | wrong-goal — <one sentence>`

   Check: over/under-scope; existing mitigations vs prevention; smaller alternatives; externally unverifiable claims (verify primary sources yourself when cited).

5. **Standards and intended behavior** — separately check applicable documented coding standards and fidelity to the originating plan/spec/acceptance criteria. Then assess errors/recovery, concurrency, security, abuse, scale, blast radius, rollback, tests, documentation, and current external library/API claims. Use [references/review-checklists.md](references/review-checklists.md); keep only relevant sections.

6. **Compound knowledge lens (when artifacts exist)** — if learnings, workflow receipts, or compound schemas are in scope, check for contradictions with current source and freshness/lifecycle problems (`active` vs `stale`/`superseded`, missing `schema_version`, overdue verification). Report conflicts for judgment; do not auto-rewrite semantic disagreements. Route refresh/capture to `$refresh-learnings` / `$capture-learning` (if installed) rather than embedding those skills here.

7. **Delegated review is opt-in only.** When the user explicitly requests an external/second-agent review, recommend or invoke existing `$use-codex` or `$use-cursor` **advisory** workflows if available. Do not automatically spend external-agent usage or fan out reviewers. This skill must not depend on those skills being installed.

8. **Report** (review/fix) must include:
   - Premise verdict
   - Findings ordered by severity with path references
   - **Test-coverage map** — for each acceptance criterion or load-bearing behavior: the test that covers it, or explicit "none"
   - **What I did not verify** — claims not personally exercised
   - In **fix** mode only: what changed; checks run

9. **prompt-only** — emit a single fenced prompt the user can paste elsewhere: context, scoped files, premise questions, relevant checklist items, required report shape (including coverage map and "what I did not verify"). No file edits.

## Hard rules

- Generic **review** never edits files.
- **fix** only when explicitly requested.
- No automatic mutation embedded in default review behavior.
- Do not commit, push, deploy, or destructively mutate.

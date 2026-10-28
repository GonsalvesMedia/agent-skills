# Verification Strategy

Discover commands from the repository. Do not assume package managers, script names, ports, or app shells.

## Discover checks

Look in order for the narrowest honest signal:

1. Plan's own Verification / Acceptance Criteria section
2. `AGENTS.md` / `CLAUDE.md` / contributing docs
3. Manifest scripts (`package.json`, `Makefile`, `justfile`, `pyproject.toml`, `Cargo.toml`, task runners)
4. CI workflow files for the canonical gate set

Record the exact commands you run.

## Scope ladder

1. **Targeted** — unit/integration tests or typecheck scoped to touched packages/paths
2. **Adjacent** — lint/format for files you changed
3. **Broad** — full test/build when the phase is cross-cutting or high risk

Prefer targeted proof for small phases; require broader gates before closing large or risky phases.

## Acceptance criteria

For each criterion in the plan:

| Classification | Meaning |
|----------------|---------|
| Pass | You personally exercised it (automated or observed) |
| Fail | Exercised and failed |
| Manual — unperformed | Requires human session, browser, credentials, or external system you did not run |
| Deferred | Explicitly out of scope for this session with reason |

Do not equate "typecheck/lint clean" with "feature works."
When adding or revising tests, prefer observable behavior over implementation details, and record any load-bearing behavior with no direct test.

## Self-review before handoff

Path-scoped diff only:

```bash
git status --short -- <paths>
git diff --stat -- <paths>
git diff -- <paths>
```

Check for accidental unrelated edits, debug leftovers, and plan-scope violations. Preserve other workstreams.

## Safety

Never commit, push, deploy, publish, migrate, reset data, or run destructive operations unless the user explicitly authorizes that exact action.

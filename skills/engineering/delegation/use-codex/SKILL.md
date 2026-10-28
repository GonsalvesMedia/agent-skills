---
name: use-codex
description: Delegate independent codebase analysis, adversarial review, debugging, implementation, or patching to OpenAI Codex CLI as an external subagent. Use only when the user explicitly asks to use Codex, requests a Codex review or second opinion, or wants Codex to patch files. Route exclusively to GPT-6 Astra, GPT-6.1 Sol, GPT-6.1 Terra, and GPT-6 Luna; default to Sol with medium reasoning.
---

# Use Codex

Run OpenAI Codex CLI as an external worker while the parent agent owns scope, safety, verification, and the final answer. Treat Codex output as evidence to inspect, not as truth.

Use `scripts/run-codex.sh` for every dispatch. The wrapper enforces the model allowlist, reasoning allowlist, and safe baseline flags.

## Choose The Model

Use only these routes. Default to `gpt-6.1-sol` with `medium` reasoning.

| Route | CLI model ID | Use for |
|---|---|---|
| Default — Sol | `gpt-6.1-sol` | Everyday independent work: reviews, implementation, debugging, broad scans, read-heavy analysis, and ordinary patching. Built for complex coding and agentic workflows with strong factual reliability |
| More capable — Astra | `gpt-6-astra` | Ambiguous, difficult, high-value, or open-ended work that needs extra planning, judgment, validation, or polish — OpenAI's most capable model |
| Lower cost — Terra | `gpt-6.1-terra` | Scoped code fixes with clear acceptance checks, concise technical writing from supplied material, and visual or computer-use tasks when the required inputs and tools are available |
| Smaller — Luna | `gpt-6-luna` | Clear, narrow, repeatable, or high-volume tasks such as extraction, classification, transformation, and structured summaries |

Try Terra when scope is clear and usage matters; prefer Sol for broad reviews, complex debugging, cross-cutting implementation, and deep research. Escalate from Sol to Astra when the task's ambiguity, risk, or need for careful judgment makes extra capability worthwhile. Use Luna only when the task is explicitly bounded and a good result is well-defined. Do not use `auto`, GPT-5.6 or any earlier generation, Spark, deprecated Codex models, model aliases, or any provider/model outside this allowlist. If an allowed model is unavailable, report the blocker instead of substituting.

Default reasoning is `medium`: it balances speed and depth. Use `low` for simple, well-scoped work; `high` for difficult multi-step work, edge cases, or security-focused review; and `xhigh` or `max` only when the added depth clearly justifies the latency and usage. `ultra` may use subagents; use it only when the user explicitly requests it and the selected model/account supports it — `gpt-6-luna` does not support `ultra`. If Codex rejects an otherwise allowed effort for the selected model or account, report the exact blocker rather than silently downgrading.

### Where Terra Fits

Practical candidates for this skill: a reproducible bug fix in a small file set, a regression test for a known failure, a localized UI correction, or documentation revised against supplied code and notes. These are routing suggestions based on [OpenAI's model-selection guidance](https://developers.openai.com/api/docs/guides/model-selection), not local benchmark results. Give Terra explicit scope and a concrete verification command; start at `medium`, or `low` for straightforward work.

Terra's visual and computer-use strengths do not add browser tools or image attachments to this wrapper. Confirm the delegated runtime can access the required inputs and tools; `--ignore-user-config` still applies. For pricing, release evidence, independent evaluations, and reasoning tradeoffs, read [references/terra.md](references/terra.md) when comparing Terra with Sol or Luna.

## Pick One Mode

### Advisory Mode

Use for reviews, research, plan validation, diagnosis, and second opinions. Codex must not edit files.

```bash
printf '%s\n' "$PROMPT" | \
  /absolute/path/to/use-codex/scripts/run-codex.sh \
  --mode advisory --workspace /absolute/path/to/repo
```

The wrapper applies `codex exec -` (prompt from stdin), `sandbox_mode="read-only"`, `approval_policy="never"`, an explicit model/reasoning level, and `--ignore-user-config`. The latter prevents user-configured MCP or provider settings from becoming an ambient delegation capability; authentication still uses Codex's normal auth state.

### Patch Mode

Use only when the user asked for implementation or file changes. Codex may edit the selected workspace and run local commands inside the workspace-write sandbox.

```bash
printf '%s\n' "$PROMPT" | \
  /absolute/path/to/use-codex/scripts/run-codex.sh \
  --mode patch --model gpt-6.1-sol --workspace /absolute/path/to/repo
```

The wrapper applies `sandbox_mode="workspace-write"`, `approval_policy="never"`, and `--ignore-user-config`. This preserves normal local editing and test/build/lint commands in the selected workspace while preventing ambient Codex configuration from adding integrations. Never add `--dangerously-bypass-approvals-and-sandbox`, `--yolo`, or `sandbox_mode="danger-full-access"`. Do not commit, push, deploy, publish, run migrations, reset databases, or mutate remote infrastructure unless the user separately authorizes that exact action and all applicable repo safety checks are satisfied.

`--add-dir` is an elevated exception: use it only when the user has separately named and authorized the additional path and why it must be writable. Do not infer it from imports, monorepo layout, or a task prompt.

## Dispatch Workflow

1. Resolve the exact repository and read its `AGENTS.md`, plus relevant local guidance such as `CLAUDE.md`, `.cursor/rules`, or project docs.
2. Inspect `git status --short`, relevant diffs, and the task scope. Use advisory mode if write authorization is absent.
3. Choose one allowed model and reasoning level. Briefly explain departures from Sol/`medium` in terms of scope, quality, latency, or usage.
4. Write a self-contained prompt with repository context, numbered objectives, explicit file scope, current errors or commands, forbidden actions, required verification, and final report format.
5. Run the wrapper. Use the parent environment's background-process support for long tasks, then monitor it; do not fire-and-forget.
6. If Codex needs follow-up after patch mode, prefer `--resume last` with the exact failure or review feedback. Keep the same model explicit.
7. Synthesize the result rather than dumping raw output.

## Prompt Requirements

For advisory mode, include:

> Read and analyze only. Do not edit, create, delete, or rename files. Return findings ordered by severity with exact file and line references, evidence, and a concrete recommendation. State explicitly if no actionable issue is found.

For patch mode, include:

> Make only the requested changes. Do not access secrets, modify `.env*`, commit, push, deploy, publish, migrate/reset databases, change remote infrastructure, or perform destructive operations. Preserve unrelated user changes. Run the narrowest relevant local checks. End with: changes made and why; checks run and results; issues found but not fixed; files changed; a **test-coverage map** — for each acceptance criterion (or load-bearing behavior) name the test that covers it, or state explicitly that none does; and a **"what I did NOT verify"** section listing every claim you did not personally exercise (a summary that says "all tests pass" is not evidence that the load-bearing path has a test — the two are different, and the gap must be declared, not glossed).

The test-coverage map and the "did NOT verify" section are the point of leverage: the recurring failure mode is not a lie but an over-claim — correct code shipped with no test on the security- or correctness-critical path, under a confident "verified" summary. Forcing the agent to enumerate coverage and non-verification converts that silent gap into a declared one the parent can act on immediately, instead of reverse-engineering coverage during review. The parent still re-runs the suite and inspects the diff regardless (see Verify Patch Mode); the report is a claim to check, never proof.

Never pass secrets in prompts or command-line flags. Prefer existing authenticated Codex login; if automation needs an API key, reference `CODEX_API_KEY` from the environment without printing it.

## Verify Patch Mode

After Codex exits:

1. Re-run `git status --short` and inspect the actual path-scoped diff.
2. Confirm every changed file belongs to the dispatched workstream; preserve unrelated changes.
3. Spot-check Codex's claims against the code.
4. **Audit the test-coverage map.** For every acceptance criterion Codex marked as having no test — and every load-bearing path (security, correctness, concurrency, data integrity) whether or not Codex flagged it — either write the missing test yourself or require it in a follow-up run before accepting. "The code is correct but untested" is the dominant failure mode; the coverage map exists so you catch it here rather than in production. Do not accept a green suite as coverage of a path the suite never exercises.
5. Run the repository's relevant tests, typecheck, lint, or build outside Codex. The parent's run is the gate of record.
6. If checks fail, resume Codex with the exact failure or fix it directly.
7. Report what changed, what was verified, and any disagreement or remaining risk. Leave changes uncommitted unless the user asks otherwise.

## Operational Notes

- Official Codex docs say `codex exec` is the non-interactive mode for scripts and supports explicit sandbox and approval settings.
- Official Codex docs say CLI model selection uses `--model` / `-m`. This skill pins the explicit `gpt-6-astra`, `gpt-6.1-sol`, `gpt-6.1-terra`, and `gpt-6-luna` IDs rather than a family alias.
- OpenAI positions Astra for the most demanding work, Sol for complex coding, Terra for visual work, writing, and scoped fixes, and Luna for efficient high-volume work. This skill keeps `medium` as its default reasoning level. A stale local `/model` picker can omit a newly released model that is still directly callable via `-m`; pass the explicit ID and surface any access error.
- Workspace-write mode keeps network access off unless explicitly enabled. Do not enable command network access unless the task requires it and the user placed that need in scope.
- Codex can read, write, delete, and run shell commands inside its configured sandbox. The sandbox is the enforcement boundary; prompt prohibitions are scope guidance, not a substitute for it. Keep prompts and file scope restrictive.
- Parallel Codex runs multiply usage and can collide in a dirty worktree. Default to one run.

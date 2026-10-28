---
name: use-claude
description: Delegate independent codebase analysis, review, debugging, implementation, or patching to Claude Code CLI. Use when the user explicitly asks to use Claude or Claude Code, requests a Claude second opinion, wants Claude to patch files, or asks to delegate a well-scoped task to Claude. Use Sonnet by default and Opus for difficult, high-judgment work.
---

# Use Claude

Run Claude Code as an external worker while the parent agent owns scope, safety, verification, and the final answer. Treat Claude output as evidence to inspect, not truth.

Use `scripts/run-claude.sh` for every dispatch. It is subscription-only: it uses the existing Claude Code `/login` subscription session and deliberately clears API-key, bearer-token, setup-token, and cloud-provider credential overrides. The wrapper accepts only documented model aliases and capability-tiered advisory or patch modes.

## Choose the model

| Route | Model | Use for |
|---|---|---|
| Default | `sonnet` | Focused reviews, implementation, debugging, analysis, and ordinary patching |
| More capable | `opus` | Ambiguous, difficult, high-value, security-sensitive, or design-heavy work |

Prefer Sonnet. Escalate to Opus when judgment and ambiguity—not task size alone—justify it. Do not substitute a model when the requested one is unavailable.

Both routes use Claude Code's `sonnet`/`opus` aliases, which resolve to the latest Sonnet and Opus so the skill tracks new versions without an edit. Verified on CLI 2.1.284: `sonnet` → `claude-sonnet-5-5`, `opus` → `claude-opus-5-5`. Caveat: a CLI can briefly lag a same-day model release (2.1.278 still resolved `opus` to the legacy `claude-opus-5` the day Opus 5.5 shipped), so after a model launch run `claude update` and re-probe with `--output-format json` (check `canonicalModel`); pin the explicit dated ID only if an alias still points at the old version.

## Pick one mode

### Advisory mode

Use for reviews, research, diagnosis, plan validation, and second opinions. The wrapper exposes only `Read`, `Glob`, and `Grep`, uses plan mode, and ignores ambient MCP configuration. Claude therefore cannot edit files or run shell commands through its built-in tool set.

```bash
printf '%s\n' "$PROMPT" | \
  /absolute/path/to/use-claude/scripts/run-claude.sh \
  --mode advisory --workspace /absolute/path/to/repo
```

### Patch mode

Use only when the user asked for implementation or file changes. This is the normal engineering tier: it exposes `Read`, `Glob`, `Grep`, `Edit`, `Write`, `Bash`, and `WebFetch`, with ordinary network access for research, fetches, package work, and local test/build/lint workflows. It remains subscription-only and disables ambient hooks, project/user customizations, and MCP configuration.

```bash
printf '%s\n' "$PROMPT" | \
  /absolute/path/to/use-claude/scripts/run-claude.sh \
  --mode patch --model sonnet --workspace /absolute/path/to/repo
```

Never add `--dangerously-skip-permissions`, broaden write scope, or pass an MCP config. Do not commit, push, deploy, publish, migrate/reset databases, or mutate remote infrastructure unless the user separately authorizes the exact action.

### Sandboxed patch mode

Use `sandboxed-patch` when the user wants a deliberately contained local edit. It retains workspace edits plus local test/build/lint commands, but fails closed if Claude's native sandbox is unavailable, blocks network access, disables unsandboxed fallback, and denies common credential paths/variables.

```bash
printf '%s\n' "$PROMPT" | \
  /absolute/path/to/use-claude/scripts/run-claude.sh \
  --mode sandboxed-patch --model sonnet --workspace /absolute/path/to/repo
```

### Full mode

Use `full` only when the user explicitly asks for Claude's normal ambient project capabilities, such as project/user instructions, hooks, configured MCP integrations, or an unsandboxed workflow. It deliberately does not apply `--safe-mode`, `--strict-mcp-config`, or a built-in tool allowlist. The parent must inspect the project configuration and state the specific expanded capability in the prompt.

`--add-dir` is an elevated exception: use it only when the user separately names and authorizes the extra path and its write need. Do not infer it from repository layout or a task prompt.

## Dispatch workflow

1. Resolve the repository and read `AGENTS.md`, `CLAUDE.md`, and relevant local guidance yourself.
2. Inspect the scoped worktree state and use advisory mode without explicit write authorization.
3. Write a self-contained prompt: objective, the relevant reviewed repository guidance, exact file scope, constraints, verification, prohibited actions, and report format. Advisory, patch, and sandboxed-patch use `--safe-mode`, so Claude does not load repository or user `CLAUDE.md`, skills, hooks, plugins, MCP, custom commands, or agents on its own. `full` is the explicit exception.
4. Run the wrapper and monitor the completed process. Do not fire-and-forget.
5. Resume only with a captured session ID and the same model. Never use an ambient "last session" selector.
6. Inspect Claude's path-scoped diff and rerun relevant checks yourself before accepting its claims.

## Prompt requirements

For advisory mode, include:

> Read and analyze only. Do not edit, create, delete, rename files, or run shell commands. Return findings ordered by severity with exact file and line references, evidence, and a concrete recommendation. State explicitly if no actionable issue is found.

For patch mode, include:

> Make only the requested changes. Do not access secrets, modify `.env*`, commit, push, deploy, publish, migrate/reset databases, change remote infrastructure, or perform destructive operations. Preserve unrelated user changes. Run the narrowest relevant local checks. End with: changes made and why; checks run and results; issues found but not fixed; files changed; a test-coverage map for each acceptance criterion or load-bearing behavior; and a "what I did NOT verify" section.

## Verify patch mode

1. Re-run path-scoped status and diff commands.
2. Confirm every changed file belongs to the dispatched workstream.
3. Audit the test-coverage map, especially security, correctness, concurrency, and data-integrity paths.
4. Run relevant tests, typecheck, lint, or build outside Claude.
5. Report what changed, what was verified, disagreement or remaining risk, and leave changes uncommitted unless the user asks otherwise.

## Availability

The wrapper reports a clear blocker if `claude` is not installed or authenticated with a Claude subscription via `/login`. `--bare` requires API authentication and is prohibited for this skill. Advisory, patch, and sandboxed-patch launch with `--safe-mode` and `--strict-mcp-config`; full deliberately does not. Claude's documented one-shot text form takes the prompt as an argument, so the wrapper cannot provide Codex-style stdin end-to-end transport; never put secrets in prompts.

Do not install, authenticate, or change Claude configuration unless the user asks.

---
name: use-kimi
description: Delegate independent codebase analysis, adversarial review, debugging, implementation, or patching to Kimi Code CLI as an external subagent. Use only when the user explicitly asks to use Kimi, requests a Kimi review or second opinion, or wants Kimi to patch files. Route exclusively to the Moonshot K2.7 Coding and K3 families; default to K2.7 Coding.
---

# Use Kimi

Run Kimi Code CLI as an external worker while the parent agent owns scope, safety, verification, and the final answer. Treat Kimi output as evidence to inspect, not as truth.

Use `scripts/run-kimi.sh` for every dispatch. The wrapper enforces the model allowlist, generates a hermetic config, and applies the permission rules that make advisory mode read-only.

## Read This First: Prompts Are Not Enforcement

Kimi's non-interactive `--prompt` mode **auto-approves tool calls**. Verified on v0.29.2: `kimi -p "create a file..."` created the file even with `default_permission_mode = "manual"`, because there is no human present to answer the approval prompt. The model's own transcript said *"auto permission mode is active, so I should continue normally without pausing for approval."*

So an instruction like "read only, do not edit files" is scope guidance, **not** a boundary. Read-only behavior comes from `[[permission.rules]]` deny rules in the config the wrapper generates — verified to work: Write and Bash were denied while Read succeeded, and no files appeared on disk.

Never dispatch Kimi with a bare `kimi -p` for advisory work. Always go through the wrapper.

## Choose The Model

Default to `kimi-code/kimi-for-coding`.

| Route | CLI model ID | Context | Plan | Use for |
|---|---|---|---|---|
| Default — K2.7 Code | `kimi-code/kimi-for-coding` | 256k | All | Everyday independent work: reviews, implementation, debugging, read-heavy analysis, ordinary patching |
| More capable — K3 | `kimi-code/k3` | 1M (256k on Moderato) | Moderato+ | Ambiguous, difficult, or high-value work needing extra judgment; also whole-repo sweeps that genuinely exceed 256k |
| K3, bounded context | `kimi-code/k3-256k` | 256k | Moderato+ | K3-family capability at lower consumption; the safe K3 route when the 1M window isn't needed or isn't available |
| Faster K2.7 — **3× quota** | `kimi-code/kimi-for-coding-highspeed` | 256k | Allegretto+ | Same coding ability as the default, ~5–6× faster output. A latency-for-quota trade, not a capability trade |

K3 is the flagship (2.8T parameters), so escalate to it the way you would to Codex's Sol: when ambiguity, risk, or the need for careful judgment makes the extra capability worth it. Large context is a second reason to reach for it, not the only one.

`kimi-for-coding-highspeed` is **not** a cheaper or weaker model — per Moonshot's docs it has the same coding ability and buys ~5–6× output speed at **3× quota usage**. On a usage-metered plan that makes it a deliberate choice for when latency genuinely matters, never a default.

Do not use provider/model routes outside this allowlist, and do not point the wrapper at a different provider. If an allowed model is unavailable, report the blocker instead of substituting.

`--effort low|high|max` applies to the K3 models only, defaulting to `high`. The K2.7 models expose no effort levels (they run thinking always-on), and the wrapper rejects `--effort` for them. Use `low` for bounded mechanical work and `max` only when the added depth clearly justifies the latency and usage.

Two plan-dependent limits worth knowing before dispatch, since neither is discoverable from local state: K3's 1M window requires Allegretto or above (Moderato caps K3 at 256k), and `kimi-for-coding-highspeed` requires Allegretto or above. The wrapper declares `max_context_size = 1048576` for `kimi-code/k3`, matching the value Moonshot ships in the stock `config.toml`. On a Moderato plan prefer `kimi-code/k3-256k` rather than relying on a 1M window the account cannot serve.

## Pick One Mode

### Advisory Mode

Use for reviews, research, plan validation, diagnosis, and second opinions. Kimi cannot edit files.

```bash
printf '%s\n' "$PROMPT" | \
  /absolute/path/to/use-kimi/scripts/run-kimi.sh \
  --mode advisory --workspace /absolute/path/to/repo
```

The wrapper denies `Write`, `Edit`, `Bash`, `Agent`, `AgentSwarm`, `Skill`, `FetchURL`, `WebSearch`, and the goal/cron tools. Denying `Bash` wholesale — rather than by command pattern — is what makes advisory mode airtight: there is no shell to write through. `FetchURL`/`WebSearch` are denied so a review of untrusted code cannot become an exfiltration path.

### Patch Mode

Use only when the user asked for implementation or file changes. Kimi may edit the workspace and run local commands.

```bash
printf '%s\n' "$PROMPT" | \
  /absolute/path/to/use-kimi/scripts/run-kimi.sh \
  --mode patch --workspace /absolute/path/to/repo
```

Patch mode sets `default_permission_mode = "yolo"` and keeps `Write`/`Edit`/`Bash`, while denying `Agent`/`AgentSwarm` (no delegated fan-out and no multiplied usage) and a list of destructive or infrastructure-mutating commands: `rm -rf`, `sudo`, `git push`, `git commit`, `git reset --hard`, `git clean`, `npm/pnpm/yarn publish`, `vercel deploy`, `wrangler deploy`/`d1`/`secret`/`r2`/`kv`, `supabase db push`/`db reset`/`link`, `drizzle-kit push`, `prisma migrate`/`db push`, `docker system prune`, `gh release`, `gh secret`.

Those patterns are wildcard-wrapped on both sides (`Bash(*rm -rf*)`), because a bare prefix pattern only matches the start of the command string — `touch a && rm -rf b` slips straight past `Bash(rm -rf*)`. That bypass was observed in testing and then confirmed fixed. The infra entries are deliberately narrow (`*supabase db push*`, not `*supabase*`) so ordinary work like `grep -r supabase .` is not collateral damage; both behaviors are verified.

**Understand the limit of that list.** Kimi has no OS-level filesystem sandbox — unlike Codex's `sandbox_mode`, enforcement is per-tool and per-command-string, and it constrains only what the deny list anticipates. Plain `rm file` is intentionally still allowed, nothing stops writes outside the workspace, and a novel phrasing of a destructive command will pass. Patch mode is therefore **meaningfully weaker isolation than Codex patch mode**: it stops footguns, not a determined or confused agent. Prefer Codex for patch work in a dirty or high-stakes worktree, keep Kimi's file scope tight, and make sure the work is committed or otherwise recoverable before dispatching.

`--add-dir` is an elevated exception: use it only when the user has separately named and authorized the additional path and why it must be writable. Do not infer it from imports or monorepo layout.

## Dispatch Workflow

1. Resolve the exact repository and read its `AGENTS.md`, plus relevant local guidance such as `CLAUDE.md` or project docs.
2. Inspect `git status --short`, relevant diffs, and the task scope. Use advisory mode if write authorization is absent.
3. Choose one allowed model and effort. State why anything other than the K2.7 Coding default is warranted.
4. Write a self-contained prompt with repository context, numbered objectives, explicit file scope, current errors or commands, forbidden actions, required verification, and final report format.
5. Run the wrapper. Use the parent environment's background-process support for long tasks, then monitor it; do not fire-and-forget.
6. For follow-up, resume with `--session <id>` (Kimi prints the id as `To resume this session: kimi -r session_...`) or `--continue` for the last session in that workspace. Keep the same model explicit.
7. Synthesize the result rather than dumping raw output.

## Prompt Requirements

For advisory mode, include:

> Read and analyze only. Return findings ordered by severity with exact file and line references, evidence, and a concrete recommendation. State explicitly if no actionable issue is found.

For patch mode, include:

> Make only the requested changes. Do not access secrets, modify `.env*`, commit, push, deploy, publish, migrate/reset databases, change remote infrastructure, or perform destructive operations. Preserve unrelated user changes. Run the narrowest relevant local checks. End with: changes made and why; checks run and results; issues found but not fixed; files changed; a **test-coverage map** — for each acceptance criterion (or load-bearing behavior) name the test that covers it, or state explicitly that none does; and a **"what I did NOT verify"** section listing every claim you did not personally exercise (a summary that says "all tests pass" is not evidence that the load-bearing path has a test — the two are different, and the gap must be declared, not glossed).

The test-coverage map and the "did NOT verify" section are the point of leverage: the recurring failure mode is not a lie but an over-claim — correct code shipped with no test on the security- or correctness-critical path, under a confident "verified" summary. Forcing the agent to enumerate coverage and non-verification converts that silent gap into a declared one the parent can act on immediately. The parent still re-runs the suite and inspects the diff regardless.

Never pass secrets in prompts. The wrapper passes the prompt via `--prompt` in argv, which is visible in the process list on a shared machine — one more reason secrets never belong in a delegation prompt.

## Verify Patch Mode

After Kimi exits:

1. Re-run `git status --short` and inspect the actual path-scoped diff.
2. Confirm every changed file belongs to the dispatched workstream; preserve unrelated changes. Because patch mode has no filesystem sandbox, check for stray writes outside the intended scope rather than assuming they cannot exist.
3. Spot-check Kimi's claims against the code.
4. **Audit the test-coverage map.** For every acceptance criterion marked as having no test — and every load-bearing path (security, correctness, concurrency, data integrity) whether or not Kimi flagged it — either write the missing test yourself or require it in a follow-up run before accepting. Do not accept a green suite as coverage of a path the suite never exercises.
5. Run the repository's relevant tests, typecheck, lint, or build outside Kimi. The parent's run is the gate of record.
6. If checks fail, resume with `--session` and the exact failure, or fix it directly.
7. Report what changed, what was verified, and any disagreement or remaining risk. Leave changes uncommitted unless the user asks otherwise.

## Operational Notes

- The model roster is documented at `https://www.kimi.com/code/docs/en/kimi-code/models`. The four IDs in the allowlist match both that page and the stock local `config.toml`; re-check the page when Moonshot ships a new family, since plan gating and quota multipliers live there and are not discoverable from local state.
- Kimi Code CLI installs to `~/.kimi-code/bin`; add that to PATH in your shell profile. Non-interactive shells may not load the profile; if `kimi` is not found, invoke it by absolute path or export the PATH entry first.
- The wrapper builds a hermetic delegation home at `~/.kimi-code-delegate` (override with `--home`) containing a generated `config.toml` and a symlink to `~/.kimi-code/credentials`. Your personal `~/.kimi-code/config.toml` is never read, so user MCP servers and provider settings cannot become an ambient delegation capability. Auth reuses the existing OAuth login; run `kimi login` if credentials are missing.
- The home is stable rather than temporary because sessions live inside `KIMI_CODE_HOME` — a temp home would make `--session`/`--continue` unusable.
- `kimi doctor` validates config files and is the fastest way to confirm a generated config parses.
- TOML ordering is load-bearing in the generated config: a bare top-level key placed after a table header silently becomes a member of that table. This is not theoretical — it is what made an early version of this wrapper drop `default_model` and fail with "No model configured."
- `--output-format stream-json` (via `--json`) is available when you need structured events instead of text.
- Parallel Kimi runs multiply usage and can collide in a dirty worktree. Default to one run.

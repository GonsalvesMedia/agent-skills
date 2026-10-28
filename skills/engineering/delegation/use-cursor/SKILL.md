---
name: use-cursor
description: Delegate independent codebase analysis, adversarial review, debugging, implementation, or patching to Cursor Agent CLI as an external subagent. Use only when the user explicitly asks to use Cursor, requests a Cursor review or second opinion, or wants Cursor to patch files. Route exclusively to Composer 2.5 or Grok 4.7; default to Grok 4.7 high with fast mode off; never use Cursor Auto or any other model family.
---

# Use Cursor

Run Cursor Agent CLI as an external worker while the parent agent owns scope, safety, verification, and the final answer. Treat Cursor output as evidence to inspect, not as truth.

Use `scripts/run-cursor.sh` for every dispatch. The wrapper enforces the model allowlist and safe baseline flags. For a run that may take more than a brief response, start it through `scripts/start-cursor.sh` so the parent observes a real process and captured final output instead of treating initial silence as failure.

## Choose the model

Use only these routes. Default to `grok-4.7-high` (high reasoning, fast off).

| Route | CLI model ID | Use for |
|---|---|---|
| Default | `grok-4.7-high` | Everyday independent work: reviews, implementation, debugging, architecture, and security reasoning |
| Fast | `grok-4.7-high-fast` | The same work when latency is explicitly more important than usage cost |
| Composer | `composer-2.5` | Focused coding, implementation, refactors, tests, and bounded reviews when Composer is explicitly preferred |
| Composer fast | `composer-2.5-fast` | Composer work when latency matters enough to justify higher usage cost |

Prefer `grok-4.7-high`. Do not use a `-fast` variant unless latency is explicitly more important than usage cost. Do not use `auto`: Auto may silently select a model outside the allowlist. Do not substitute another model if an allowed model is unavailable; report the blocker.

The wrapper also accepts Grok 4.7 low, medium, and extra-high variants for an explicitly requested effort level, but do not choose them by default.

`grok-4.7-*` is the direct-xAI listing, not the Cursor-brokered `cursor-grok-*` family (which tops out at 4.6). This skill routes to 4.7 by deliberate choice; do not silently fall back to a `cursor-grok-*` route.

## Pick one mode

### Advisory mode

Use for reviews, research, plan validation, diagnosis, and second opinions. Cursor must not edit files.

```bash
printf '%s\n' "$PROMPT" | \
  /absolute/path/to/use-cursor/scripts/run-cursor.sh \
  --mode advisory --workspace /absolute/path/to/repo
```

The wrapper applies `--mode ask`, `--sandbox enabled`, `--print`, `--trust`, and JSON output. Cursor documents `ask` as read-only/planning, so it is the strongest advisory restriction exposed by the CLI.

### Patch mode

Use only when the user asked for implementation or file changes. Cursor may edit the selected workspace and run local commands.

```bash
printf '%s\n' "$PROMPT" | \
  /absolute/path/to/use-cursor/scripts/run-cursor.sh \
  --mode patch --workspace /absolute/path/to/repo
```

The wrapper applies `--force` for unattended writes while retaining `--sandbox enabled`. Cursor documents `--force` as allowing commands unless explicitly denied by its configured permission rules; it is not a general security boundary. Never add `--yolo`, `--approve-mcps`, extra workspace directories, plugins, or disable the sandbox. Existing project/global Cursor permission and MCP configuration can still affect the run, so inspect them before dispatch and do not claim this wrapper independently disables ambient MCP integrations.

For a dirty worktree, overlapping agents, or risky refactors, use Cursor's isolated worktree support:

```bash
printf '%s\n' "$PROMPT" | \
  /absolute/path/to/use-cursor/scripts/run-cursor.sh \
  --mode patch --workspace /absolute/path/to/repo \
  --worktree use-cursor-task-name
```

Do not create a baseline commit, commit Cursor's changes, merge a worktree, or push unless the user separately authorizes it.

## Dispatch workflow

1. Resolve the exact repository and read its `AGENTS.md`, `CLAUDE.md`, and relevant `.cursor/rules`. Cursor also loads these rules, but the parent must understand them before delegation.
2. Inspect `git status --short`, relevant diffs, and the task scope. Use advisory mode if write authorization is absent.
3. Choose a model from the table and state why a Fast variant, Composer, or a non-high Grok effort is warranted when not using the default.
4. Write a self-contained prompt with:
   - repository and task context;
   - numbered objectives and explicit file scope;
   - relevant current behavior, errors, and commands;
   - forbidden actions and out-of-scope areas;
   - required verification and final report format.
5. Run the wrapper. If the parent environment has native background-process support that captures output and signals completion, use that first — it needs no polling and reports the child's exit status directly. Only when the parent lacks it, and the run is expected to take more than about 30 seconds, use the persistent capture pattern below. Either way, do not fire-and-forget, and do not infer failure merely because output is initially empty.
6. If Cursor asks a question in its final response, answer by starting a fresh, fully contextualized run. Resume a Cursor session only when its session ID is reliably captured and the same model remains explicitly selected.
7. Synthesize the result rather than dumping raw output.

### Persistent capture pattern (fallback when the parent has no native background support)

Create a prompt file outside the repository (for example with `mktemp`), then
launch the existing wrapper through the helper. The prompt and captured files
must never contain secrets. Use distinct names per run; do not start a competing
run while one is active.

```bash
cursor_task_dir="$(mktemp -d /tmp/use-cursor.XXXXXX)"
cursor_prompt="$cursor_task_dir/prompt.txt"
cursor_output="$cursor_task_dir/output.json"
cursor_error="$cursor_task_dir/error.log"
cursor_status="$cursor_task_dir/status"
cursor_pid="$cursor_task_dir/pid"

# Write the already-reviewed non-secret prompt to "$cursor_prompt".
/absolute/path/to/use-cursor/scripts/start-cursor.sh \
  --prompt-file "$cursor_prompt" \
  --output "$cursor_output" \
  --error "$cursor_error" \
  --status-file "$cursor_status" \
  --pid-file "$cursor_pid" \
  -- /absolute/path/to/use-cursor/scripts/run-cursor.sh \
  --mode advisory --workspace /absolute/path/to/repo
```

`start-cursor.sh` exits 0 as soon as the child is launched, so its own status
says nothing about the run. `--status-file` carries the real exit status and is
written only when the run ends.

Poll in bounded rounds. Each round waits at most a minute, then reports progress
to the user and returns; repeat rounds until the run ends or you hit the total
budget you set for the task (a deep Grok review can legitimately take many
minutes). Never block a single call indefinitely.

```bash
cursor_run_pid="$(cat "$cursor_pid")"

# One bounded round: wait up to 60s, then fall through and report.
waited=0
while [ "$waited" -lt 60 ] && kill -0 "$cursor_run_pid" 2>/dev/null; do
  sleep 5
  waited=$((waited + 5))
done

if kill -0 "$cursor_run_pid" 2>/dev/null; then
  printf 'still running (pid %s, %ss elapsed this round)\n' "$cursor_run_pid" "$waited"
elif [ ! -f "$cursor_status" ]; then
  printf 'process gone with no status file: the run was killed, not completed\n'
  sed -n '1,120p' "$cursor_error"
else
  printf 'exit status: %s\n' "$(cat "$cursor_status")"
  sed -n '1,240p' "$cursor_output"
  sed -n '1,120p' "$cursor_error"
fi
```

Interpret the result by status first, not by output size. A non-zero status with
empty output is a real failure whose reason is in the error file — a rejected
model and Cursor's own empty-output guard both land here, and both look
identical if you only check whether the output file is empty. Do not call Cursor
unsuccessful while its PID is alive, and do not treat a zero-byte output file as
failure before the status file exists: the wrapper buffers the whole response,
so that file stays empty until the run ends.

Retry at most once, only after the previous run has exited. Keep the prompt,
output, error, and status paths long enough to inspect and synthesize the
result, then remove the temporary directory.

## Prompt requirements

For advisory mode, include:

> Read and analyze only. Do not edit, create, delete, or rename files. Return findings ordered by severity with exact file and line references, evidence, and a concrete recommendation. State explicitly if no actionable issue is found.

For patch mode, include:

> Make only the requested changes. Do not access secrets, modify `.env*`, commit, push, deploy, publish, migrate/reset databases, change remote infrastructure, or perform destructive operations. Preserve unrelated user changes. Run the narrowest relevant local checks. End with: changes made and why; checks run and results; issues found but not fixed; files changed; a **test-coverage map** — for each acceptance criterion (or load-bearing behavior) name the test that covers it, or state explicitly that none does; and a **"what I did NOT verify"** section listing every claim you did not personally exercise (a summary that says "all tests pass" is not evidence that the load-bearing path has a test — the two are different, and the gap must be declared, not glossed).

The test-coverage map and the "did NOT verify" section are the point of leverage: the recurring failure mode is not a lie but an over-claim — correct code shipped with no test on the security- or correctness-critical path, under a confident "verified" summary. Forcing the agent to enumerate coverage and non-verification converts that silent gap into a declared one the parent can act on immediately, instead of reverse-engineering coverage during review. The parent still re-runs the suite and inspects the diff regardless (see Verify patch mode); the report is a claim to check, never proof.

Never pass secrets in prompts or command-line flags. Prefer existing authenticated Cursor login; if automation needs an API key, reference `CURSOR_API_KEY` from the environment without printing it.

## Verify patch mode

After Cursor exits:

1. Re-run `git status --short` and inspect the actual path-scoped diff.
2. Confirm every changed file belongs to the dispatched workstream; preserve unrelated changes.
3. Spot-check Cursor's claims against the code.
4. **Audit the test-coverage map.** For every acceptance criterion Cursor marked as having no test — and every load-bearing path (security, correctness, concurrency, data integrity) whether or not Cursor flagged it — either write the missing test yourself or require it in a follow-up run before accepting. "The code is correct but untested" is the dominant failure mode; the coverage map exists so you catch it here rather than in production. Do not accept a green suite as coverage of a path the suite never exercises.
5. Run the repository's relevant tests, typecheck, lint, or build outside Cursor. The parent's run is the gate of record.
6. If checks fail, give Cursor the exact failure in a new constrained run or fix it directly.
7. Report what changed, what was verified, and any disagreement or remaining risk. Leave changes uncommitted unless the user asks otherwise.

## Operational notes

- Verify available IDs with `cursor agent --list-models`; do not route dynamically from that list.
- Use `--output-format json` so the parent can capture the final result and session ID.
- Cursor can read, write, delete, and run shell commands. Keep repository permissions restrictive, including denies for `.env*`, private keys, destructive shell commands, and external mutation tools. `--sandbox enabled` and prompt instructions reduce risk but do not replace a reviewed permission configuration.
- Cursor's documented CLI does not offer a counterpart to Claude's `--strict-mcp-config`. Do not add `--approve-mcps`, plugins, or extra workspace roots. Inspect project/global MCP and permission configuration before dispatch; external mutations remain forbidden unless the user explicitly placed them in scope and all applicable safety checks are satisfied.
- Cursor's documented one-shot interface takes a positional prompt, so the wrapper cannot provide Codex-style stdin end-to-end transport. Never include secrets in prompts.
- Parallel Cursor runs multiply usage and create collision risk. Default to one run; use isolated worktrees for explicitly requested parallel patch work.

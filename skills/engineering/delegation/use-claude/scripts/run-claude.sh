#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: run-claude.sh --mode advisory|patch|sandboxed-patch|full --workspace PATH [options]

Read the Claude prompt from stdin.

Allowed models:
  sonnet             (alias — latest Sonnet, currently Sonnet 5.5)
  opus               (alias — latest Opus, currently Opus 5.5)

Options:
  --model MODEL          Default: sonnet
  --max-turns COUNT      Default: 12
  --resume SESSION_ID    Resume a captured Claude session ID
  --add-dir PATH         Additional writable path for patch mode
EOF
}

mode=""
model="sonnet"
workspace=""
max_turns="12"
resume=""
add_dirs=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode) [ "$#" -ge 2 ] || { usage >&2; exit 2; }; mode=$2; shift 2 ;;
    --model) [ "$#" -ge 2 ] || { usage >&2; exit 2; }; model=$2; shift 2 ;;
    --workspace) [ "$#" -ge 2 ] || { usage >&2; exit 2; }; workspace=$2; shift 2 ;;
    --max-turns) [ "$#" -ge 2 ] || { usage >&2; exit 2; }; max_turns=$2; shift 2 ;;
    --resume) [ "$#" -ge 2 ] || { usage >&2; exit 2; }; resume=$2; shift 2 ;;
    --add-dir) [ "$#" -ge 2 ] || { usage >&2; exit 2; }; add_dirs="${add_dirs}
$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$mode" in advisory|patch|sandboxed-patch|full) ;; *) printf 'Invalid mode: %s\n' "$mode" >&2; usage >&2; exit 2 ;; esac
# Both routes use Claude Code's model aliases, which resolve to the latest
# Sonnet/Opus so the skill tracks new versions without an edit. Verified on CLI
# 2.1.284: `sonnet` -> claude-sonnet-5-5, `opus` -> claude-opus-5-5 (via
# --output-format json canonicalModel). Caveat: a CLI can briefly lag a same-day
# release — 2.1.278 still resolved `opus` to legacy claude-opus-5 the day Opus
# 5.5 shipped — so after a model launch, `claude update` and re-probe; pin the
# explicit dated ID only if an alias still points at the old version.
case "$model" in sonnet|opus) ;; *) printf 'Disallowed model: %s\n' "$model" >&2; exit 2 ;; esac
case "$max_turns" in ''|*[!0-9]*) printf 'Invalid --max-turns: %s\n' "$max_turns" >&2; exit 2 ;; esac

[ -n "$workspace" ] || { printf 'Missing --workspace\n' >&2; exit 2; }
[ -d "$workspace" ] || { printf 'Workspace is not a directory: %s\n' "$workspace" >&2; exit 2; }
workspace=$(cd "$workspace" && pwd -P)
cd "$workspace"

command -v claude >/dev/null 2>&1 || {
  printf 'Claude Code CLI is not available on PATH. Install and authenticate it before using this skill.\n' >&2
  exit 127
}

prompt=$(sed -n '1,$p')
[ -n "$prompt" ] || { printf 'Prompt must be provided on stdin\n' >&2; exit 2; }

# This wrapper is subscription-only. Claude Code gives cloud-provider, bearer,
# API-key, apiKeyHelper, and setup-token credentials precedence over the OAuth
# login created by `claude auth login`. `--safe-mode` disables file-based
# customizations (including credential helpers); clear every documented
# environment override so an authenticated `/login` subscription is the only
# usable non-managed credential source. Do not replace this with `--bare`:
# bare mode intentionally skips OAuth/keychain reads and requires API auth.
unset ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY CLAUDE_CODE_OAUTH_TOKEN
unset CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY

auth_status=$(claude auth status --json 2>/dev/null) || {
  printf 'Claude Code is not authenticated. Run `claude auth login` with your Claude subscription before using this skill.\n' >&2
  exit 1
}
if ! printf '%s' "$auth_status" | grep -Eq '"authMethod"[[:space:]]*:[[:space:]]*"claude\.ai"' || \
   ! printf '%s' "$auth_status" | grep -Eq '"apiProvider"[[:space:]]*:[[:space:]]*"firstParty"' || \
   ! printf '%s' "$auth_status" | grep -Eq '"subscriptionType"[[:space:]]*:[[:space:]]*"[^"[:space:]]+"'; then
  printf 'Claude Code is not using a first-party Claude.ai subscription session. This skill permits subscription usage only; run `claude auth login` and retry.\n' >&2
  exit 1
fi

set -- claude -p --output-format json --model "$model" --max-turns "$max_turns"

if [ -n "$resume" ]; then
  set -- "$@" --resume "$resume"
fi

if [ "$mode" = full ]; then
  # Explicitly requested normal Claude Code surface: project/user instructions,
  # hooks, MCP, and built-in tools remain available under Claude's ordinary
  # permission configuration. This wrapper still never uses API/cloud auth or
  # dangerously-skip-permissions.
  set -- "$@" --permission-mode acceptEdits
elif [ "$mode" = advisory ]; then
  # Restrict available built-ins, rather than claiming a few literal command
  # deny patterns can contain a general-purpose shell.
  set -- "$@" --safe-mode --strict-mcp-config \
    --permission-mode plan --tools 'Read,Glob,Grep'
elif [ "$mode" = patch ]; then
  # Normal engineering profile: retain a clean subscription-authenticated
  # Claude surface while permitting workspace edits, Bash, WebFetch, and
  # network access for research and ordinary local engineering work.
  set -- "$@" --safe-mode --strict-mcp-config \
    --permission-mode acceptEdits \
    --tools 'Read,Glob,Grep,Edit,Write,Bash,WebFetch' \
    --allowedTools 'Read,Glob,Grep,Edit,Write,Bash,WebFetch'
else
  # Patch runs keep Bash for normal edit/test/build/lint work, but every Bash
  # process must be contained by Claude Code's native sandbox. `safe-mode`
  # prevents ordinary repository/user settings from widening this run; the
  # explicit settings also fail closed when the platform sandbox is missing
  # and disable Claude's unsandboxed retry escape hatch. No command is
  # excluded from the sandbox and outbound domains are denylisted by default.
  #
  # The credential deny list is intentionally limited to ambient credential
  # locations/variables. The workspace remains readable and writable so local
  # test, build, and lint commands retain their normal project scope. A task
  # that genuinely requires network access or an external writable directory
  # must be run by the parent under separately authorized tooling, not by
  # weakening this delegated patch profile.
  patch_settings='{"sandbox":{"enabled":true,"failIfUnavailable":true,"allowUnsandboxedCommands":false,"excludedCommands":[],"filesystem":{"denyRead":["~/.ssh","~/.aws","~/.config/gcloud","~/.config/gh","~/.kube"],"denyWrite":["~/.ssh","~/.aws","~/.config/gcloud","~/.config/gh","~/.kube"]},"network":{"deniedDomains":["*"]},"credentials":{"files":[{"path":"~/.ssh","mode":"deny"},{"path":"~/.aws","mode":"deny"},{"path":"~/.config/gcloud","mode":"deny"},{"path":"~/.config/gh","mode":"deny"},{"path":"~/.kube","mode":"deny"}],"envVars":[{"name":"AWS_ACCESS_KEY_ID","mode":"deny"},{"name":"AWS_SECRET_ACCESS_KEY","mode":"deny"},{"name":"AWS_SESSION_TOKEN","mode":"deny"},{"name":"GITHUB_TOKEN","mode":"deny"},{"name":"GH_TOKEN","mode":"deny"},{"name":"NPM_TOKEN","mode":"deny"},{"name":"NODE_AUTH_TOKEN","mode":"deny"},{"name":"CLOUDFLARE_API_TOKEN","mode":"deny"},{"name":"VERCEL_TOKEN","mode":"deny"},{"name":"SUPABASE_ACCESS_TOKEN","mode":"deny"},{"name":"STRIPE_SECRET_KEY","mode":"deny"}]}}}'
  set -- "$@" --safe-mode --strict-mcp-config \
    --permission-mode acceptEdits \
    --tools 'Read,Glob,Grep,Edit,Write,Bash' \
    --allowedTools 'Read,Glob,Grep,Edit,Write,Bash' \
    --settings "$patch_settings"
fi

if [ -n "$add_dirs" ]; then
  [ "$mode" = patch ] || { printf 'Cannot use --add-dir in advisory mode\n' >&2; exit 2; }
  while IFS= read -r extra_dir; do
    [ -n "$extra_dir" ] || continue
    [ -d "$extra_dir" ] || { printf 'Additional path is not a directory: %s\n' "$extra_dir" >&2; exit 2; }
    extra_dir=$(cd "$extra_dir" && pwd -P)
    set -- "$@" --add-dir "$extra_dir"
  done <<EOF
$add_dirs
EOF
fi

# Claude Code's documented one-shot text interface takes a positional prompt;
# it does not provide Codex's `-` stdin-prompt form. Keeping the prompt in a
# shell variable avoids a prompt file, but callers must not pass secrets and
# should keep prompts within their platform's argument-size limit.
# Tool-list options are variadic. The `--` separator prevents them from
# consuming the positional prompt that follows.
#
# Do not let an exit-0, zero-byte response look like a completed delegation.
# In that case there is neither a result nor a session ID for the caller to
# inspect or resume, so return a distinct, actionable failure instead.
if output=$("$@" -- "$prompt"); then
  if [ -z "$(printf '%s' "$output" | tr -d '[:space:]')" ]; then
    printf '%s\n' \
      'Claude completed successfully but returned no output; no review result or session ID was captured.' >&2
    exit 1
  fi
  printf '%s\n' "$output"
else
  status=$?
  [ -z "$output" ] || printf '%s\n' "$output"
  exit "$status"
fi

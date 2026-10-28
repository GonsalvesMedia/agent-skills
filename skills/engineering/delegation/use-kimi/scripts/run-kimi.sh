#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: run-kimi.sh --mode advisory|patch --workspace PATH [options]

Read the Kimi prompt from stdin.

Allowed models:
  kimi-code/kimi-for-coding             (default, "K2.7 Coding")
  kimi-code/kimi-for-coding-highspeed   ("K2.7 Coding Highspeed")
  kimi-code/k3                          ("K3", 1M context, efforts)
  kimi-code/k3-256k                     ("K3-256k", 256k context, efforts)

Options:
  --model MODEL       Default: kimi-code/kimi-for-coding
  --effort LEVEL      low|high|max — k3 models only (default: high)
  --output FILE       Also write the final response to FILE
  --session ID        Resume an existing session by id
  --continue          Continue the previous session for this workspace
  --add-dir PATH      Additional workspace directory (patch mode only)
  --json              Emit stream-json instead of text
  --home PATH         Delegation home (default: $HOME/.kimi-code-delegate)

The wrapper builds a hermetic KIMI_CODE_HOME containing a generated
config.toml plus a symlink to your real credentials. It never reads your
personal ~/.kimi-code/config.toml, so user MCP servers and provider
settings cannot become an ambient delegation capability.
EOF
}

mode=""
model="kimi-code/kimi-for-coding"
workspace=""
effort=""
output=""
session=""
continue_session=0
json=0
add_dirs=""
home=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode)      [ "$#" -ge 2 ] || { usage >&2; exit 2; }; mode=$2; shift 2 ;;
    --model)     [ "$#" -ge 2 ] || { usage >&2; exit 2; }; model=$2; shift 2 ;;
    --workspace) [ "$#" -ge 2 ] || { usage >&2; exit 2; }; workspace=$2; shift 2 ;;
    --effort)    [ "$#" -ge 2 ] || { usage >&2; exit 2; }; effort=$2; shift 2 ;;
    --output)    [ "$#" -ge 2 ] || { usage >&2; exit 2; }; output=$2; shift 2 ;;
    --session)   [ "$#" -ge 2 ] || { usage >&2; exit 2; }; session=$2; shift 2 ;;
    --home)      [ "$#" -ge 2 ] || { usage >&2; exit 2; }; home=$2; shift 2 ;;
    --add-dir)   [ "$#" -ge 2 ] || { usage >&2; exit 2; }; add_dirs="${add_dirs}
$2"; shift 2 ;;
    --continue)  continue_session=1; shift ;;
    --json)      json=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$mode" in
  advisory|patch) ;;
  *) printf 'Invalid mode: %s\n' "$mode" >&2; usage >&2; exit 2 ;;
esac

# Model allowlist, with the per-model metadata the generated config needs.
case "$model" in
  kimi-code/kimi-for-coding)           bare="kimi-for-coding";           ctx=262144;  efforts=0 ;;
  kimi-code/kimi-for-coding-highspeed) bare="kimi-for-coding-highspeed"; ctx=262144;  efforts=0 ;;
  kimi-code/k3)                        bare="k3";                        ctx=1048576; efforts=1 ;;
  kimi-code/k3-256k)                   bare="k3-256k";                   ctx=262144;  efforts=1 ;;
  *) printf 'Disallowed model: %s\n' "$model" >&2; exit 2 ;;
esac

if [ -n "$effort" ]; then
  case "$effort" in
    low|high|max) ;;
    *) printf 'Disallowed effort: %s\n' "$effort" >&2; exit 2 ;;
  esac
  [ "$efforts" -eq 1 ] || {
    printf 'Model %s does not support --effort\n' "$model" >&2
    exit 2
  }
fi

[ -n "$workspace" ] || { printf 'Missing --workspace\n' >&2; exit 2; }
[ -d "$workspace" ] || { printf 'Workspace is not a directory: %s\n' "$workspace" >&2; exit 2; }
workspace=$(cd "$workspace" && pwd -P)

if [ "$mode" = advisory ] && [ -n "$add_dirs" ]; then
  printf 'Cannot use --add-dir in advisory mode\n' >&2
  exit 2
fi

command -v kimi >/dev/null 2>&1 || {
  printf 'Kimi Code CLI is not available on PATH.\n' >&2
  printf 'It installs to ~/.kimi-code/bin — ensure that is on PATH.\n' >&2
  exit 127
}

real_home="${KIMI_CODE_REAL_HOME:-$HOME/.kimi-code}"
[ -e "$real_home/credentials" ] || {
  printf 'No Kimi credentials at %s/credentials. Run: kimi login\n' "$real_home" >&2
  exit 3
}

# Stable (not temporary) home so --session / --continue can resume prior runs.
delegate_home=${home:-"$HOME/.kimi-code-delegate"}
mkdir -p "$delegate_home"
[ -e "$delegate_home/credentials" ] || ln -s "$real_home/credentials" "$delegate_home/credentials"
[ -e "$delegate_home/device_id" ] || {
  [ -f "$real_home/device_id" ] && cp "$real_home/device_id" "$delegate_home/device_id"
} 2>/dev/null || true

if [ "$mode" = advisory ]; then
  permission_mode="manual"
else
  permission_mode="yolo"
fi

config="$delegate_home/config.toml"

# TOML ordering matters: every bare top-level key must precede the first table
# header, or it silently becomes a member of that table.
{
  printf 'default_model = "%s"\n' "$model"
  printf 'default_permission_mode = "%s"\n' "$permission_mode"
  printf '\n'

  printf '[providers."managed:kimi-code"]\n'
  printf 'type = "kimi"\n'
  printf 'api_key = ""\n'
  printf 'base_url = "https://api.kimi.com/coding/v1"\n\n'
  printf '[providers."managed:kimi-code".oauth]\n'
  printf 'storage = "file"\n'
  printf 'key = "oauth/kimi-code"\n\n'

  printf '[models."%s"]\n' "$model"
  printf 'provider = "managed:kimi-code"\n'
  printf 'model = "%s"\n' "$bare"
  printf 'max_context_size = %s\n' "$ctx"
  printf 'capabilities = [ "thinking", "always_thinking", "image_in", "tool_use" ]\n'
  [ -n "$effort" ] && printf 'default_effort = "%s"\n' "$effort"
  printf '\n'

  printf '[loop_control]\n'
  printf 'max_retries_per_step = 3\n'
  printf 'reserved_context_size = 50000\n\n'

  printf '[thinking]\n'
  printf 'enabled = true\n\n'

  emit_deny() {
    printf '[[permission.rules]]\n'
    printf 'decision = "deny"\n'
    printf 'pattern = "%s"\n' "$1"
    printf 'reason = "%s"\n\n' "$2"
  }

  if [ "$mode" = advisory ]; then
    # Advisory is enforced by denying every mutating tool outright. Denying
    # Bash wholesale (rather than by pattern) is what makes this airtight.
    for t in Write Edit Bash Agent AgentSwarm Skill FetchURL WebSearch \
             CronCreate CronDelete CreateGoal UpdateGoal SetGoalBudget; do
      emit_deny "$t" "advisory mode is read-only"
    done
  else
    # Patch mode keeps Write/Edit/Bash, but blocks fan-out and the
    # destructive / infrastructure-mutating commands.
    for t in Agent AgentSwarm CronCreate CronDelete; do
      emit_deny "$t" "no delegated fan-out or scheduling"
    done
    # Patterns are wrapped in wildcards on BOTH sides: a bare prefix pattern
    # only matches the start of the command string, so `touch a && rm -rf b`
    # would slip past `Bash(rm -rf*)`. Verified: `Bash(*rm -rf*)` blocks it.
    # Kept deliberately specific (`*supabase db push*`, not `*supabase*`) so
    # ordinary reads like `grep -r supabase` are not collateral damage.
    for p in '*rm -rf*' '*sudo *' '*git push*' '*git commit*' \
             '*git reset --hard*' '*git clean -*' '*git checkout -- *' \
             '*npm publish*' '*pnpm publish*' '*yarn publish*' \
             '*vercel deploy*' '*vercel --prod*' \
             '*wrangler deploy*' '*wrangler d1 *' '*wrangler secret*' \
             '*wrangler r2 *' '*wrangler kv*' '*wrangler pages deploy*' \
             '*supabase db push*' '*supabase db reset*' '*supabase link*' \
             '*drizzle-kit push*' '*prisma migrate*' '*prisma db push*' \
             '*docker system prune*' '*gh release *' '*gh secret *'; do
      emit_deny "Bash($p)" "destructive or infrastructure-mutating"
    done
  fi
} > "$config"

kimi_prompt=$(cat)
[ -n "$kimi_prompt" ] || { printf 'Empty prompt on stdin\n' >&2; exit 2; }

cd "$workspace"

set -- kimi --model "$model"

if [ -n "$session" ]; then
  set -- "$@" --session "$session"
elif [ "$continue_session" -eq 1 ]; then
  set -- "$@" --continue
fi

if [ "$json" -eq 1 ]; then
  set -- "$@" --output-format stream-json
fi

if [ -n "$add_dirs" ]; then
  while IFS= read -r add_dir; do
    [ -n "$add_dir" ] || continue
    [ -d "$add_dir" ] || {
      printf 'Additional path is not a directory: %s\n' "$add_dir" >&2
      exit 2
    }
    add_dir=$(cd "$add_dir" && pwd -P)
    set -- "$@" --add-dir "$add_dir"
  done <<EOF
$add_dirs
EOF
fi

export KIMI_CODE_HOME="$delegate_home"

# Capture rather than `tee`: in a `cmd | tee FILE` pipeline the shell reports
# tee's status, so a failing Kimi run exited 0 here and read as a clean
# delegation. Capturing gives one code path that reports Kimi's own status and
# lets the empty-output guard inspect the response.
#
# Do not let an exit-0, zero-byte response look like a completed delegation.
# In that case there is neither a result nor a session ID for the caller to
# inspect or resume, so return a distinct, actionable failure instead.
#
# Tradeoff: nothing reaches the caller until the run ends, which suppresses the
# incremental event stream under `--json` (`--output-format stream-json`).
# Delegation reads the response after completion, so that is acceptable here;
# revisit this branch first if live streaming is ever needed.
if kimi_response=$("$@" --prompt "$kimi_prompt"); then
  if [ -z "$(printf '%s' "$kimi_response" | tr -d '[:space:]')" ]; then
    printf '%s\n' \
      'Kimi completed successfully but returned no output; no result or session ID was captured.' >&2
    exit 1
  fi
  [ -z "$output" ] || printf '%s\n' "$kimi_response" > "$output"
  printf '%s\n' "$kimi_response"
else
  status=$?
  if [ -n "$kimi_response" ]; then
    # Preserve partial output on failure: it usually carries the reason.
    [ -z "$output" ] || printf '%s\n' "$kimi_response" > "$output"
    printf '%s\n' "$kimi_response"
  fi
  exit "$status"
fi

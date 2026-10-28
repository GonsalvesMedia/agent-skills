#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: run-codex.sh --mode advisory|patch --workspace PATH [options]

Read the Codex prompt from stdin.

Allowed models:
  gpt-6-astra
  gpt-6.1-sol
  gpt-6.1-terra
  gpt-6-luna

Options:
  --model MODEL                 Default: gpt-6.1-sol
  --reasoning LEVEL             Default: medium
                               low|medium|high|xhigh|max|ultra
                               (gpt-6-luna does not support ultra)
  --output FILE                 Write the final message to FILE as well as normal stdout
  --resume SESSION_ID|last      Resume an existing Codex exec session
  --add-dir PATH                Additional writable path for patch mode
  --json                        Stream JSONL events to stdout
EOF
}

mode=""
model="gpt-6.1-sol"
workspace=""
reasoning="medium"
output=""
resume=""
json=0
add_dirs=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      mode=$2
      shift 2
      ;;
    --model)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      model=$2
      shift 2
      ;;
    --workspace)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      workspace=$2
      shift 2
      ;;
    --reasoning)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      reasoning=$2
      shift 2
      ;;
    --output)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      output=$2
      shift 2
      ;;
    --resume)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      resume=$2
      shift 2
      ;;
    --add-dir)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      add_dirs="${add_dirs}
$2"
      shift 2
      ;;
    --json)
      json=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$mode" in
  advisory|patch) ;;
  *) printf 'Invalid mode: %s\n' "$mode" >&2; usage >&2; exit 2 ;;
esac

case "$model" in
  gpt-6-astra|gpt-6.1-sol|gpt-6.1-terra|gpt-6-luna) ;;
  *) printf 'Disallowed model: %s\n' "$model" >&2; exit 2 ;;
esac

# GPT-6 documents low..ultra (gpt-6-luna caps at max, no ultra). The wrapper
# permits the shared range; Codex rejects an unsupported effort for the chosen
# model at runtime, which the skill surfaces as an actionable blocker.
case "$reasoning" in
  low|medium|high|xhigh|max|ultra) ;;
  *) printf 'Disallowed reasoning: %s\n' "$reasoning" >&2; exit 2 ;;
esac

[ -n "$workspace" ] || { printf 'Missing --workspace\n' >&2; exit 2; }
[ -d "$workspace" ] || { printf 'Workspace is not a directory: %s\n' "$workspace" >&2; exit 2; }
workspace=$(cd "$workspace" && pwd -P)
cd "$workspace"

command -v codex >/dev/null 2>&1 || {
  printf 'Codex CLI is not available on PATH\n' >&2
  exit 127
}

if [ -n "$resume" ]; then
  set -- codex exec resume
  if [ "$resume" = "last" ]; then
    set -- "$@" --last
  else
    set -- "$@" "$resume"
  fi
else
  set -- codex exec
fi

set -- "$@" \
  --model "$model" \
  --ignore-user-config \
  -c 'approval_policy="never"' \
  -c "model_reasoning_effort=\"$reasoning\""

if [ -n "$output" ]; then
  set -- "$@" --output-last-message "$output"
fi

if [ "$mode" = advisory ]; then
  set -- "$@" -c 'sandbox_mode="read-only"'
else
  set -- "$@" -c 'sandbox_mode="workspace-write"'
fi

if [ "$json" -eq 1 ]; then
  set -- "$@" --json
fi

if [ -n "$add_dirs" ]; then
  while IFS= read -r add_dir; do
    [ -n "$add_dir" ] || continue
    [ "$mode" = patch ] || {
      printf 'Cannot use --add-dir in advisory mode\n' >&2
      exit 2
    }
    [ -d "$add_dir" ] || {
      printf 'Additional path is not a directory: %s\n' "$add_dir" >&2
      exit 2
    }
  done <<EOF
$add_dirs
EOF

  while IFS= read -r add_dir; do
    [ -n "$add_dir" ] || continue
    add_dir=$(cd "$add_dir" && pwd -P)
    set -- "$@" --add-dir "$add_dir"
  done <<EOF
$add_dirs
EOF
fi

# `codex exec -` is the documented stdin form. Keep the prompt out of argv so
# arbitrary prompt size is supported without a temporary file. The prompt still
# arrives on this wrapper's stdin, which the command substitution below inherits.
#
# Do not let an exit-0, zero-byte response look like a completed delegation.
# In that case there is neither a result nor a session ID for the caller to
# inspect or resume, so return a distinct, actionable failure instead.
#
# Tradeoff: capturing means nothing reaches the caller until the run ends. That
# is free for the default one-shot text response, but it does suppress the
# incremental event stream under `--json` — revisit this branch first if live
# streaming is ever needed. `--output-last-message` is unaffected: Codex writes
# that file itself.
if codex_response=$("$@" -); then
  if [ -z "$(printf '%s' "$codex_response" | tr -d '[:space:]')" ]; then
    printf '%s\n' \
      'Codex completed successfully but returned no output; no result or session ID was captured.' >&2
    exit 1
  fi
  printf '%s\n' "$codex_response"
else
  status=$?
  [ -z "$codex_response" ] || printf '%s\n' "$codex_response"
  exit "$status"
fi

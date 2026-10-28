#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: run-cursor.sh --mode advisory|patch --workspace PATH [--model MODEL] [--worktree NAME]

Read the Cursor prompt from stdin. Allowed models:
  grok-4.7-high                   (default)
  grok-4.7-high-fast
  grok-4.7-low
  grok-4.7-low-fast
  grok-4.7-medium
  grok-4.7-medium-fast
  grok-4.7-xhigh
  grok-4.7-xhigh-fast
  composer-2.5
  composer-2.5-fast
EOF
}

mode=""
model="grok-4.7-high"
workspace=""
worktree=""

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
    --worktree)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      worktree=$2
      shift 2
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
  composer-2.5|composer-2.5-fast|\
  grok-4.7-low|grok-4.7-low-fast|\
  grok-4.7-medium|grok-4.7-medium-fast|\
  grok-4.7-high|grok-4.7-high-fast|\
  grok-4.7-xhigh|grok-4.7-xhigh-fast) ;;
  *) printf 'Disallowed model: %s\n' "$model" >&2; exit 2 ;;
esac

[ -n "$workspace" ] || { printf 'Missing --workspace\n' >&2; exit 2; }
[ -d "$workspace" ] || { printf 'Workspace is not a directory: %s\n' "$workspace" >&2; exit 2; }
workspace=$(cd "$workspace" && pwd -P)

command -v cursor >/dev/null 2>&1 || {
  printf 'Cursor CLI is not available on PATH\n' >&2
  exit 127
}

prompt=$(sed -n '1,$p')
[ -n "$prompt" ] || { printf 'Prompt must be provided on stdin\n' >&2; exit 2; }

set -- cursor agent \
  --print \
  --trust \
  --sandbox enabled \
  --output-format json \
  --model "$model" \
  --workspace "$workspace"

if [ -n "$worktree" ]; then
  set -- "$@" --worktree "$worktree"
fi

if [ "$mode" = advisory ]; then
  set -- "$@" --mode ask
else
  set -- "$@" --force
fi

# Cursor Agent's documented one-shot interface takes a positional prompt; it has
# no equivalent of Codex's `-` stdin-prompt form, so the prompt cannot be handed
# to Cursor as a file. (A caller may still stage its prompt in a temp file and
# redirect it into this wrapper's stdin — that is start-cursor.sh's pattern and
# is unrelated.) Do not put secrets in prompts and keep them within
# argument-size limits.
#
# Do not let an exit-0, zero-byte response look like a completed delegation.
# In that case there is neither a result nor a session ID for the caller to
# inspect or resume, so return a distinct, actionable failure instead.
#
# Tradeoff: capturing into `$output` means nothing reaches the caller until the
# run ends, so a capture file stays zero-byte for the whole run. That is free
# under `--output-format json` (Cursor emits one blob at exit anyway), but it
# would suppress incremental output if this ever moves to a streaming format —
# revisit this branch first if so.
if output=$("$@" "$prompt"); then
  if [ -z "$(printf '%s' "$output" | tr -d '[:space:]')" ]; then
    printf '%s\n' \
      'Cursor completed successfully but returned no output; no review result or session ID was captured.' >&2
    exit 1
  fi
  printf '%s\n' "$output"
else
  status=$?
  [ -z "$output" ] || printf '%s\n' "$output"
  exit "$status"
fi

#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: start-cursor.sh --prompt-file PATH --output PATH --error PATH --status-file PATH [--pid-file PATH] -- run-cursor.sh arguments

Starts a persistent Cursor run in the background. The prompt is read from the
given file; final stdout (normally Cursor JSON) and stderr are written to the
given paths. Prints the child PID and, when requested, writes it to --pid-file.

--status-file is required and is the only way the caller learns the run's exit
status: this helper always returns 0 once the child is launched, so a rejected
model, a missing wrapper, or run-cursor.sh's empty-output guard would otherwise
be indistinguishable from success. The file does not exist until the run ends,
so its absence while the PID is gone means the run was killed rather than
completed.
EOF
}

prompt_file=""
output_file=""
error_file=""
status_file=""
pid_file=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --prompt-file)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      prompt_file=$2
      shift 2
      ;;
    --output)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      output_file=$2
      shift 2
      ;;
    --error)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      error_file=$2
      shift 2
      ;;
    --status-file)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      status_file=$2
      shift 2
      ;;
    --pid-file)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      pid_file=$2
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[ -n "$prompt_file" ] || { printf 'Missing --prompt-file\n' >&2; exit 2; }
[ -r "$prompt_file" ] || { printf 'Prompt file is not readable: %s\n' "$prompt_file" >&2; exit 2; }
[ -n "$output_file" ] || { printf 'Missing --output\n' >&2; exit 2; }
[ -n "$error_file" ] || { printf 'Missing --error\n' >&2; exit 2; }
[ -n "$status_file" ] || { printf 'Missing --status-file\n' >&2; exit 2; }
[ "$#" -gt 0 ] || { printf 'Missing run-cursor.sh arguments after --\n' >&2; exit 2; }

# Keep only the final completed response in each capture file. This is a local
# orchestration helper, not a permission boundary; run-cursor.sh still owns the
# allowed model/mode checks.
: > "$output_file"
: > "$error_file"
# Removed rather than truncated: the status file's existence is the caller's
# completion signal, so an empty leftover must not read as "finished".
rm -f "$status_file"

# The prompt is redirected rather than piped so that `$?` is unambiguously the
# wrapper's own exit status and not a pipeline's last stage.
nohup sh -c '
  prompt=$1
  output=$2
  error=$3
  status=$4
  shift 4
  "$@" <"$prompt" >"$output" 2>"$error"
  printf "%s\n" "$?" > "$status"
' sh "$prompt_file" "$output_file" "$error_file" "$status_file" "$@" </dev/null >/dev/null 2>&1 &

pid=$!
if [ -n "$pid_file" ]; then
  printf '%s\n' "$pid" > "$pid_file"
fi
printf '%s\n' "$pid"

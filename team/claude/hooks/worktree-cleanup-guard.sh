#!/usr/bin/env bash
# worktree-cleanup-guard.sh — PreToolUse hook (Bash)
# Checkpoint 3 of the worktree lifecycle system: the only hard block. Refuses
# to remove a git worktree that still has uncommitted work (tracked or
# untracked). Fails open on any error other than a confirmed dirty worktree.
#
# Handles command chaining (;, &&, ||, |, newline) by checking every segment
# independently, quoted paths (including quoted paths containing spaces, via
# quote-aware tokenizing with Python's shlex), multi-target `rm -rf`,
# trailing slashes, and `rm` recursive+force detection regardless of flag
# order/bundling/case (-rf, -fr, -Rf, -r -f, --recursive --force, and
# /bin/rm or /usr/bin/rm invocations of the same).
#
# Scope boundary: this is a quote-aware argument parser, not a full shell
# interpreter. Command substitution ($(...)) and variable indirection
# (x=$path; rm -rf $x) are explicitly out of scope and not defended against.

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
[ -z "$cmd" ] && { echo '{}'; exit 0; }

strip_quotes() {
  local t="$1"
  t="${t%\"}"; t="${t#\"}"
  t="${t%\'}"; t="${t#\'}"
  echo "$t"
}

# Quote-aware tokenizer for a single command segment, using Python's shlex
# module (Python 3 is already a hard dependency of this hook family via
# task_record.py). This correctly keeps a quoted path with an internal space
# (e.g. "wt space") as a single token, unlike plain whitespace splitting.
# Populates the global array `tokens`. On any failure (python3 missing,
# invalid JSON, shlex parse error), sets `tokens` to empty — callers must
# treat that as "no candidates extracted" and fail open, per this script's
# existing error handling for every other failure path.
tokenize() {
  local seg="$1"
  tokens=()
  local tokens_json
  tokens_json=$(python3 -c "import shlex, json, sys
try:
    print(json.dumps(shlex.split(sys.argv[1])))
except Exception:
    print(json.dumps([]))" "$seg" 2>/dev/null)
  [ -z "$tokens_json" ] && return
  mapfile -t tokens < <(echo "$tokens_json" | jq -r '.[]' 2>/dev/null)
}

# Split the full command into segments on ; && || | and newlines, then trim
# leading whitespace off each segment. Order matters: substitute the two-char
# operators (&&, ||) before the single-char ones (;, |) so a "||" is not
# mistaken for two separate "|" pipes.
segments=()
while IFS= read -r raw_seg; do
  seg="$(echo "$raw_seg" | sed -E 's/^[[:space:]]+//')"
  [ -z "$seg" ] && continue
  segments+=("$seg")
done < <(echo "$cmd" | sed -E 's/&&/\n/g; s/\|\|/\n/g; s/;/\n/g; s/\|/\n/g')

for seg in "${segments[@]}"; do
  candidates=()

  if echo "$seg" | grep -qE '^git worktree remove'; then
    tokenize "$seg"
    # tokens: git worktree remove [--force] <path>
    for ((i = 3; i < ${#tokens[@]}; i++)); do
      t="${tokens[$i]}"
      [ "$t" = "--force" ] && continue
      t=$(strip_quotes "$t")
      t="${t%/}"
      candidates+=("$t")
      break
    done
  elif echo "$seg" | grep -qE '^(/usr/bin/|/bin/)?rm([[:space:]]|$)'; then
    tokenize "$seg"
    cmd_token="${tokens[0]:-}"
    if [[ "$cmd_token" == "rm" || "$cmd_token" == "/bin/rm" || "$cmd_token" == "/usr/bin/rm" ]]; then
      # Detect recursive-intent and force-intent independently, regardless of
      # flag order/bundling/case (rm -rf, -fr, -Rf, -r -f, --recursive --force
      # are all equivalent for this purpose). This is deliberately a scan for
      # the *presence* of both intents, not a full rm option-grammar parser.
      has_recursive=0
      has_force=0
      for ((i = 1; i < ${#tokens[@]}; i++)); do
        t="${tokens[$i]}"
        case "$t" in
          --recursive) has_recursive=1 ;;
          --force) has_force=1 ;;
          --*) : ;; # other long flags (e.g. --interactive) — not our concern
          -*)
            [[ "$t" =~ [rR] ]] && has_recursive=1
            [[ "$t" =~ f ]] && has_force=1
            ;;
        esac
      done
      if [ "$has_recursive" -eq 1 ] && [ "$has_force" -eq 1 ]; then
        for ((i = 1; i < ${#tokens[@]}; i++)); do
          t="${tokens[$i]}"
          [[ "$t" == -* ]] && continue
          t=$(strip_quotes "$t")
          t="${t%/}"
          candidates+=("$t")
        done
      fi
    fi
  else
    continue
  fi

  for candidate in "${candidates[@]}"; do
    [ -z "$candidate" ] && continue
    [ -d "$candidate" ] || continue
    # Cross-check against the registered worktree list, scoped to the
    # candidate path itself via `-C` rather than the hook's own ambient cwd.
    # This is correct regardless of what repo the hook process happens to be
    # running in, and regardless of any `cd` earlier in a chained command
    # (e.g. `cd <other-repo> && rm -rf <dirty-path-in-other-repo>`), because
    # `-C "$candidate"` makes git operate as if invoked from that directory.
    # Uses `--porcelain` (one `worktree <path>` line per entry, path runs to
    # end of line) rather than the plain columnar format, because the plain
    # format's `awk '{print $1}'` breaks on a worktree path that itself
    # contains a space (the padded branch/commit columns become ambiguous
    # with the path's own internal whitespace).
    git -C "$candidate" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' | grep -qxF "$candidate" || continue

    dirty=$(git -C "$candidate" status --porcelain -uall 2>/dev/null)
    if [ -n "$dirty" ]; then
      reason="Refusing to remove worktree at $candidate: it has uncommitted work.
$dirty
Commit or stash the changes first, or explicitly confirm with the user that this should be discarded before removing the worktree."
      jq -n --arg reason "$reason" \
        '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
      exit 0
    fi
  done
done

echo '{}'

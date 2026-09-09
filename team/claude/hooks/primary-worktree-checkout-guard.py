#!/usr/bin/env python3
"""primary-worktree-checkout-guard — PreToolUse hook (Bash).

Refuses any HEAD-moving `git checkout` / `git switch` when the command runs in
the PRIMARY worktree of a repo. Parallel feature work (multiple Claude sessions
in the same clone) must happen in separate worktrees, because a branch switch in
a shared directory rewrites the files under every other session pointed there.

Allowed, never blocked:
  - file restores:  git checkout -- <path>,  git checkout <ref> -- <path>,
                    git checkout .,          git restore ...
  - anything run inside a LINKED worktree (that is the whole point)
  - one-shot override:  ALLOW_PRIMARY_CHECKOUT=1 git switch <branch>
  - the string "git checkout" appearing only inside a heredoc body or a quoted
    argument (e.g. a commit message) — not an actual invocation

Enforcement by blocking, not by reminding. Fails OPEN on any parse error or
non-git command.

(Logic lives here in Python; the sibling .sh is a thin wrapper. macOS bash 3.2
mis-parses `$(... <<'EOF' ...)` command substitution, which broke the previous
all-in-one shell version.)
"""

import json
import os
import re
import shlex
import subprocess
import sys


def _fail_open():
    raise SystemExit(0)


def main():
    raw = sys.stdin.read()
    try:
        cmd = json.loads(raw).get("tool_input", {}).get("command", "")
    except Exception:
        _fail_open()
    if not cmd:
        _fail_open()

    if "ALLOW_PRIMARY_CHECKOUT=1" in cmd:
        _fail_open()

    d = os.getcwd()

    def git(*args):
        return subprocess.run(
            ["git", *args], cwd=d, capture_output=True, text=True
        )

    gd = git("rev-parse", "--absolute-git-dir")
    gcd = git("rev-parse", "--git-common-dir")
    if gd.returncode != 0 or gcd.returncode != 0:
        _fail_open()

    git_dir = os.path.realpath(gd.stdout.strip())
    common = gcd.stdout.strip()
    if not os.path.isabs(common):
        common = os.path.join(d, common)
    common = os.path.realpath(common)

    # Linked worktree -> git_dir is <common>/worktrees/<name>, differs -> allow.
    if git_dir != common:
        _fail_open()

    verdict = classify(cmd)
    if not verdict:
        raise SystemExit(0)

    if verdict == "NEWBRANCH":
        msg = (
            "Blocked: git checkout -b / git switch -c creates and switches a "
            "branch in the PRIMARY worktree ({d}), where another session may be "
            "working. Use an isolated worktree instead:\n"
            "  scripts/new-worktree.sh <new-branch>\n"
            "Override once (rare): prefix with  ALLOW_PRIMARY_CHECKOUT=1"
        ).format(d=d)
    else:
        msg = (
            "Blocked: git checkout / git switch moves HEAD in the PRIMARY "
            "worktree ({d}). Another Claude session may have this directory "
            "checked out on a different branch; switching here rewrites its "
            "files. For parallel feature work use a separate worktree:\n"
            "  scripts/new-worktree.sh <branch>\n"
            "File restores (git checkout -- <path>, git restore) are "
            "unaffected. Override once (e.g. parking primary on staging): "
            "prefix with  ALLOW_PRIMARY_CHECKOUT=1"
        ).format(d=d)

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": msg,
        }
    }))
    raise SystemExit(0)


def strip_heredocs(s):
    out = s
    for m in list(re.finditer(r"""<<-?\s*(["']?)([A-Za-z_][A-Za-z0-9_]*)\1""", s)):
        word = m.group(2)
        tail = out[m.end():]
        end = re.search(r"^\s*" + re.escape(word) + r"\s*$", tail, re.M)
        out = out[:m.start()] + " " + (tail[end.end():] if end else "")
    return out


def classify(cmd):
    """Return "" / "BRANCH" / "NEWBRANCH"."""
    work = strip_heredocs(cmd)
    segments = re.split(r"&&|\|\||[;\n|]", work)
    quoted = re.compile("'[^']*'" + r'|"[^"]*"')

    for seg in segments:
        seg = quoted.sub(" ", seg).strip()
        if not seg:
            continue
        try:
            toks = shlex.split(seg)
        except ValueError:
            toks = seg.split()
        if not toks:
            continue
        i = 0
        if not (toks[i] == "git" or toks[i].endswith("/git")):
            continue
        i += 1
        while i + 1 < len(toks) and toks[i] in ("-C", "-c"):
            i += 2
        if i >= len(toks) or toks[i] not in ("checkout", "switch"):
            continue
        rest = toks[i + 1:]
        if "--" in rest:
            continue
        if toks[i] == "checkout" and rest == ["."]:
            continue
        if any(a in ("-b", "-B", "-c", "-C") for a in rest):
            return "NEWBRANCH"
        return "BRANCH"
    return ""


if __name__ == "__main__":
    main()

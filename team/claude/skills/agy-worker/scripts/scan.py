#!/usr/bin/env python3
"""Antigravity Background Worker for Claude Code.

Offloads heavy repository search, file reading, and architectural analysis
to local Antigravity (Gemini 1M context) to burn ZERO Anthropic quota tokens.
"""

import sys
import os
import subprocess
import shutil
from pathlib import Path


def main():
    if len(sys.argv) < 2:
        print("Usage: scan.py <prompt or query>", file=sys.stderr)
        sys.exit(1)

    query = " ".join(sys.argv[1:])
    cwd = os.getcwd()

    agy_bin = shutil.which("agy") or shutil.which("antigravity") or str(Path.home() / ".local" / "bin" / "agy")
    if not os.path.exists(agy_bin) and not shutil.which(agy_bin):
        print(f"Error: Antigravity CLI ('agy') not found on PATH or at {agy_bin}", file=sys.stderr)
        sys.exit(1)

    formatted_prompt = (
        f"Respond tersely in smart caveman style (only substance, no pleasantries). "
        f"Analyze the repository at {cwd} and answer this request directly: {query}"
    )

    cmd = [
        agy_bin,
        "-p",
        formatted_prompt,
        "--dangerously-skip-permissions"
    ]

    try:
        proc = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=180
        )
        if proc.returncode != 0:
            print(f"[agy-worker error]: {proc.stderr.strip()}", file=sys.stderr)
            sys.exit(proc.returncode)

        out = proc.stdout.strip()
        if not out:
            print("No output received from Antigravity worker.")
        else:
            print(out)

    except subprocess.TimeoutExpired:
        print("[agy-worker error]: Operation timed out after 3 minutes.", file=sys.stderr)
        sys.exit(124)
    except Exception as e:
        print(f"[agy-worker error]: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

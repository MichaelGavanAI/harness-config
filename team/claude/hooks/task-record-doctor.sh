#!/usr/bin/env bash
# Manual health check for the shared task-record adapter. Not wired to any lifecycle hook.
# Usage: task-record-doctor.sh   (run from inside the target git repo)

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$HOOK_DIR/task_record.py" doctor

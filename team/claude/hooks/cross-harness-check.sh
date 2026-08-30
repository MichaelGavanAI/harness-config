#!/usr/bin/env bash
HANDOFF_FILE="/home/mishka/Projects/Work/.harness/active-handoff.json"
if [[ -f "$HANDOFF_FILE" ]]; then
    cat "$HANDOFF_FILE"
fi

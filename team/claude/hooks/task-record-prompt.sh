#!/usr/bin/env bash
# DEPRECATED — no-op, kept so existing settings.json registrations don't error.
#
# This hook injected a static task-record reminder on every UserPromptSubmit.
# Per-turn reminder injection is weak enforcement (the model reads it as
# background context) and its cost grows linearly with turn count.
# The conditional work now happens in task-record-stop.sh at Stop; the standing
# rule lives in CLAUDE.md. Remove this from settings.json when convenient.
exit 0

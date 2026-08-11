#!/usr/bin/env python3
"""Shared agent-workflow task record adapter (Claude side).

Implements the CLI contract described in docs/agent-workflow/CONTRACT.md.
No third-party dependencies. Never raises a traceback to stdout/stderr —
every failure path prints one generic line and exits nonzero, so a bug
here can never look like a broken Claude Code session.

Subcommands: resolve, read-active, init-task, set-task, append-event,
finalize, doctor.
"""
import contextlib
import datetime
import fcntl
import json
import os
import re
import subprocess
import sys
import tempfile

CONTRACT_VERSION = "1.0.0"
STALE_HOURS = 24

ALLOWED_STATUS = {"active", "blocked", "awaiting_product_decision", "complete", "cancelled"}
ALLOWED_PHASE = {"assessment", "design", "planning", "implementation", "verification", "closure"}
ALLOWED_OUTCOME = {None, "met", "accepted_residual_risk", "blocked", "cancelled"}
ALLOWED_EVENT_TYPES = {
    "assessment", "decision", "plan_updated", "implementation_milestone",
    "verification", "review_finding", "finding_resolved", "blocked",
    "recovery", "product_decision_requested", "final_outcome",
    "retrospective_completed",
}

SECRET_PATTERNS = [
    re.compile(r"sk-[A-Za-z0-9]{10,}"),
    re.compile(r"ghp_[A-Za-z0-9]{10,}"),
    re.compile(r"AKIA[0-9A-Z]{10,}"),
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
    re.compile(r"(?i)(password|passwd|secret|token|api[_-]?key)\s*[:=]\s*\S+"),
    re.compile(r"(?i)\b[a-f0-9]{32,}\b"),
]
PATIENT_PATTERNS = [
    re.compile(r"(?i)\bpatient\b"),
    re.compile(r"(?i)\bmrn\b"),
    re.compile(r"(?i)\bdob\b"),
    re.compile(r"\d{3}-\d{2}-\d{4}"),
]
HOME_PATH_PATTERN = re.compile(r"(^~|^/home/|^/Users/)")


class RejectError(Exception):
    """Raised on privacy/schema rejection. Message must never contain user content."""


def die(msg):
    sys.stderr.write(msg.rstrip() + "\n")
    sys.exit(1)


def now_iso():
    return datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")


def git_root():
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=5, check=True,
        )
        return out.stdout.strip()
    except Exception:
        return None


def git_common_dir():
    """The single .git shared by every worktree of a repo — unlike --show-toplevel, this path
    is identical whether called from the main checkout or any `git worktree add` checkout, so
    it's the only place a ledger can live and be visible from every worktree at once without
    being committed (see worktree_slug for how per-worktree isolation is layered on top)."""
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--git-common-dir"],
            capture_output=True, text=True, timeout=5, check=True,
        )
        path = out.stdout.strip()
        return path if os.path.isabs(path) else os.path.abspath(path)
    except Exception:
        return None


def worktree_slug(root):
    """A filesystem-safe name for `root` (the calling worktree's own --show-toplevel), so each
    worktree gets its own task lineage under the shared git-common-dir ledger instead of every
    worktree fighting over one global 'active task'."""
    return re.sub(r"[^A-Za-z0-9._-]+", "_", root.strip("/")) or "root"


def task_root(root=None):
    root = root or git_root()
    if not root:
        return None
    marker = os.path.join(root, ".agent-workflow-location")
    if os.path.isfile(marker):
        try:
            rel = open(marker, encoding="utf-8").read().strip()
            if rel:
                return os.path.join(root, rel)
        except Exception:
            pass
    common = git_common_dir()
    if common:
        # Ledger lives under the shared .git, keyed by which worktree's toplevel is calling, so
        # it (a) is never committed/never diverges per-branch and (b) doesn't collide across the
        # many parallel worktrees this repo runs. `docs/agent-workflow/` inside the tracked
        # working tree is kept as read-only history from before this fix - never written again.
        return os.path.join(common, "agent-workflow", worktree_slug(root))
    return os.path.join(root, "docs", "agent-workflow")


def scan_privacy(obj, path=""):
    """Raise RejectError if any string value in obj matches a forbidden pattern."""
    if isinstance(obj, str):
        for pat in SECRET_PATTERNS:
            if pat.search(obj):
                raise RejectError(f"rejected: field '{path or '<value>'}' looks like a secret")
        for pat in PATIENT_PATTERNS:
            if pat.search(obj):
                raise RejectError(f"rejected: field '{path or '<value>'}' looks like patient data")
    elif isinstance(obj, dict):
        for k, v in obj.items():
            scan_privacy(v, f"{path}.{k}" if path else k)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            scan_privacy(v, f"{path}[{i}]")


def check_refs(refs, field):
    for r in refs or []:
        if HOME_PATH_PATTERN.search(r) or r.startswith("http") is False and r.startswith("/"):
            raise RejectError(f"rejected: {field} must be repository-relative, not a local/home path")


@contextlib.contextmanager
def locked(task_dir, timeout=3):
    os.makedirs(task_dir, exist_ok=True)
    lock_path = os.path.join(task_dir, ".lock")
    fd = os.open(lock_path, os.O_CREAT | os.O_RDWR)
    try:
        start = datetime.datetime.now()
        while True:
            try:
                fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if (datetime.datetime.now() - start).total_seconds() > timeout:
                    raise RejectError("rejected: task record locked by another writer, timed out")
        yield
    finally:
        with contextlib.suppress(Exception):
            fcntl.flock(fd, fcntl.LOCK_UN)
        os.close(fd)


def atomic_write(path, content):
    d = os.path.dirname(path)
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".tmp-")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(content)
        os.replace(tmp, path)
    except Exception:
        with contextlib.suppress(Exception):
            os.remove(tmp)
        raise


def task_dir_for(base, task_id):
    return os.path.join(base, "tasks", task_id)


def load_task_json(tdir):
    path = os.path.join(tdir, "task.json")
    if not os.path.isfile(path):
        raise RejectError("rejected: no task.json at that location")
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def find_active_task(base):
    tasks_root = os.path.join(base, "tasks")
    if not os.path.isdir(tasks_root):
        return None
    best = None
    for name in os.listdir(tasks_root):
        tj = os.path.join(tasks_root, name, "task.json")
        if not os.path.isfile(tj):
            continue
        try:
            with open(tj, encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            continue
        if data.get("status") != "active":
            continue
        if best is None or data.get("updated_at", "") > best.get("updated_at", ""):
            best = data
    return best


def render_active_md(data):
    lines = [
        f"# Active Task: {data.get('title', '')}",
        "",
        f"**Task ID:** {data.get('task_id', '')}",
        f"**Goal:** {data.get('goal', '')}",
        f"**Status:** {data.get('status', '')}",
        f"**Phase:** {data.get('phase', '')}",
        f"**Worktree:** {data.get('worktree', 'not yet decided')}",
        "",
        "**Spec refs:** " + ", ".join(data.get("spec_refs", []) or ["(none)"]),
        "**Plan refs:** " + ", ".join(data.get("plan_refs", []) or ["(none)"]),
        "",
        f"**Next action:** {data.get('next_action', '')}",
        f"**Blocker:** {data.get('blocker') or 'none'}",
        "",
        "**Last verified evidence:**",
    ]
    ev = data.get("last_verified_evidence") or []
    if ev:
        for e in ev:
            lines.append(f"- {e.get('kind', '')}: {e.get('reference', '')}")
    else:
        lines.append("- (none yet)")
    lines.append("")
    lines.append(f"_Updated {data.get('updated_at', '')} by {data.get('last_actor', '')}_")
    return "\n".join(lines) + "\n"


def regenerate_active_md(base, data):
    atomic_write(os.path.join(base, "active-task.md"), render_active_md(data))


def is_stale(data):
    try:
        updated = datetime.datetime.fromisoformat(data.get("updated_at", ""))
    except Exception:
        return False
    if updated.tzinfo is None:
        updated = updated.replace(tzinfo=datetime.timezone.utc)
    age_hours = (datetime.datetime.now(datetime.timezone.utc) - updated).total_seconds() / 3600
    return data.get("status") == "active" and age_hours > STALE_HOURS


# ---- subcommands ----

def cmd_resolve(args):
    root = git_root()
    if not root:
        print(json.dumps({"git_root": None, "task_dir": None, "active_task_id": None}))
        return
    base = task_root(root)
    active = find_active_task(base)
    # `task_dir` is absolute, not root-relative: since the fix moving storage under
    # --git-common-dir, the ledger lives outside the working tree (see task_root), so a path
    # relative to `root` would walk out through ".." and any caller joining it back onto
    # `root` (as the old Stop hook script did) would silently resolve to the wrong place.
    print(json.dumps({
        "git_root": root,
        "task_dir": base,
        "active_task_id": active.get("task_id") if active else None,
    }))


def cmd_read_active(args):
    root = git_root()
    if not root:
        print("no active task")
        return
    base = task_root(root)
    active = find_active_task(base)
    if not active:
        print("no active task")
        return
    md_path = os.path.join(base, "active-task.md")
    content = open(md_path, encoding="utf-8").read() if os.path.isfile(md_path) else render_active_md(active)
    if is_stale(active):
        print(f"STALE: task {active.get('task_id')} not updated in >{STALE_HOURS}h")
    print(content)


def cmd_init_task(args):
    payload = json.loads(args.json)
    for field in ("title", "goal", "next_action"):
        if not payload.get(field):
            raise RejectError(f"rejected: missing required field '{field}'")
    check_refs(payload.get("spec_refs"), "spec_refs")
    check_refs(payload.get("plan_refs"), "plan_refs")
    scan_privacy(payload)

    root = git_root()
    if not root:
        raise RejectError("rejected: not inside a git repository")
    base = task_root(root)
    today = datetime.date.today().strftime("%Y%m%d")
    tasks_root = os.path.join(base, "tasks")
    os.makedirs(tasks_root, exist_ok=True)
    seq = 1
    while os.path.isdir(os.path.join(tasks_root, f"T-{today}-{seq:03d}")):
        seq += 1
    task_id = f"T-{today}-{seq:03d}"
    tdir = task_dir_for(base, task_id)

    with locked(base):
        os.makedirs(tdir, exist_ok=True)
        data = {
            "contract_version": CONTRACT_VERSION,
            "task_id": task_id,
            "title": payload["title"],
            "goal": payload["goal"],
            "status": "active",
            "phase": payload.get("phase", "assessment"),
            "spec_refs": payload.get("spec_refs", []),
            "plan_refs": payload.get("plan_refs", []),
            "requirements": payload.get("requirements", []),
            "next_action": payload["next_action"],
            "blocker": None,
            "last_verified_evidence": [],
            "last_actor": "claude",
            "updated_at": now_iso(),
        }
        if data["phase"] not in ALLOWED_PHASE:
            raise RejectError("rejected: invalid phase")
        atomic_write(os.path.join(tdir, "task.json"), json.dumps(data, indent=2) + "\n")
        atomic_write(os.path.join(tdir, "events.jsonl"), "")
        regenerate_active_md(base, data)
    print(json.dumps({"task_id": task_id, "task_dir": os.path.relpath(tdir, root)}))


def cmd_set_task(args):
    patch = json.loads(args.json)
    scan_privacy(patch)
    if "spec_refs" in patch:
        check_refs(patch["spec_refs"], "spec_refs")
    if "plan_refs" in patch:
        check_refs(patch["plan_refs"], "plan_refs")
    if "status" in patch and patch["status"] not in ALLOWED_STATUS:
        raise RejectError("rejected: invalid status")
    if "phase" in patch and patch["phase"] not in ALLOWED_PHASE:
        raise RejectError("rejected: invalid phase")
    if "worktree" in patch:
        wt = patch["worktree"]
        if not isinstance(wt, str) or not wt:
            raise RejectError("rejected: worktree must be a non-empty string (absolute path or \"none\")")
        if wt != "none" and not wt.startswith("/"):
            raise RejectError("rejected: worktree must be an absolute path or the literal string \"none\"")

    root = git_root()
    if not root:
        raise RejectError("rejected: not inside a git repository")
    base = task_root(root)
    task_id = args.task_id
    with locked(base):
        if not task_id:
            active = find_active_task(base)
            if not active:
                raise RejectError("rejected: no active task and no --task-id given")
            task_id = active["task_id"]
        tdir = task_dir_for(base, task_id)
        data = load_task_json(tdir)
        data.update(patch)
        data["updated_at"] = now_iso()
        data["last_actor"] = "claude"
        atomic_write(os.path.join(tdir, "task.json"), json.dumps(data, indent=2) + "\n")
        regenerate_active_md(base, data)
    print(json.dumps({"task_id": task_id, "updated_at": data["updated_at"]}))


def cmd_append_event(args):
    payload = json.loads(args.json)
    for field in ("type", "summary", "rationale"):
        if not payload.get(field):
            raise RejectError(f"rejected: missing required field '{field}'")
    if payload["type"] not in ALLOWED_EVENT_TYPES:
        raise RejectError("rejected: invalid event type")
    scan_privacy(payload)

    root = git_root()
    if not root:
        raise RejectError("rejected: not inside a git repository")
    base = task_root(root)
    task_id = args.task_id
    with locked(base):
        if not task_id:
            active = find_active_task(base)
            if not active:
                raise RejectError("rejected: no active task and no --task-id given")
            task_id = active["task_id"]
        tdir = task_dir_for(base, task_id)
        data = load_task_json(tdir)
        events_path = os.path.join(tdir, "events.jsonl")
        existing = 0
        if os.path.isfile(events_path):
            with open(events_path, encoding="utf-8") as f:
                existing = sum(1 for line in f if line.strip())
        event = {
            "event_id": f"E{existing + 1:04d}",
            "timestamp": now_iso(),
            "task_id": task_id,
            "actor": payload.get("actor", "claude"),
            "type": payload["type"],
            "summary": payload["summary"],
            "rationale": payload["rationale"],
            "requirement_ids": payload.get("requirement_ids", []),
            "evidence": payload.get("evidence", []),
            "outcome": payload.get("outcome", {}),
        }
        with open(events_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(event) + "\n")
        data["updated_at"] = now_iso()
        data["last_actor"] = "claude"
        atomic_write(os.path.join(tdir, "task.json"), json.dumps(data, indent=2) + "\n")
        regenerate_active_md(base, data)
    print(json.dumps({"event_id": event["event_id"], "task_id": task_id}))


def cmd_finalize(args):
    payload = json.loads(args.json) if args.json else {}
    scan_privacy(payload)
    status = payload.get("status", "complete")
    if status not in ("complete", "cancelled"):
        raise RejectError("rejected: finalize status must be complete or cancelled")

    root = git_root()
    if not root:
        raise RejectError("rejected: not inside a git repository")
    base = task_root(root)
    task_id = args.task_id
    with locked(base):
        if not task_id:
            active = find_active_task(base)
            if not active:
                raise RejectError("rejected: no active task and no --task-id given")
            task_id = active["task_id"]
        tdir = task_dir_for(base, task_id)
        data = load_task_json(tdir)
        for req in data.get("requirements", []):
            if req.get("outcome") not in ALLOWED_OUTCOME or req.get("outcome") is None:
                raise RejectError("rejected: every requirement must have a non-null outcome before finalize")
        if not data.get("last_verified_evidence"):
            raise RejectError("rejected: finalize requires at least one last_verified_evidence entry")

        events_path = os.path.join(tdir, "events.jsonl")
        events = []
        if os.path.isfile(events_path):
            with open(events_path, encoding="utf-8") as f:
                events = [json.loads(line) for line in f if line.strip()]

        retro = [
            f"# Retrospective: {data.get('title', '')}",
            "",
            f"**Goal:** {data.get('goal', '')}",
            f"**Delivered result:** {payload.get('delivered_result', '(see requirements below)')}",
            "",
            "## Requirement outcomes",
        ]
        for req in data.get("requirements", []):
            retro.append(f"- {req.get('id')}: {req.get('text')} — {req.get('outcome')}")
        retro += ["", "## Verified evidence"]
        for e in data.get("last_verified_evidence", []):
            retro.append(f"- {e.get('kind')}: {e.get('reference')}")
        retro += ["", "## Timeline"]
        for e in events:
            retro.append(f"- [{e.get('type')}] {e.get('summary')} — {e.get('rationale')}")
        retro += ["", f"## Residual risks / follow-up", payload.get("follow_up", "(none noted)"), ""]
        atomic_write(os.path.join(tdir, "retrospective.md"), "\n".join(retro) + "\n")

        data["status"] = status
        data["phase"] = "closure"
        data["updated_at"] = now_iso()
        data["last_actor"] = "claude"
        atomic_write(os.path.join(tdir, "task.json"), json.dumps(data, indent=2) + "\n")
        regenerate_active_md(base, data)

        with open(events_path, "a", encoding="utf-8") as f:
            existing = len(events)
            f.write(json.dumps({
                "event_id": f"E{existing + 1:04d}",
                "timestamp": now_iso(),
                "task_id": task_id,
                "actor": "claude",
                "type": "retrospective_completed",
                "summary": "Retrospective generated at closure.",
                "rationale": "Task reached a terminal status.",
                "requirement_ids": [],
                "evidence": [{"kind": "file", "reference": os.path.relpath(os.path.join(tdir, "retrospective.md"), root)}],
                "outcome": {"status": status},
            }) + "\n")
    print(json.dumps({"task_id": task_id, "status": status}))


def cmd_doctor(args):
    report = {"contract_version_expected": CONTRACT_VERSION}
    root = git_root()
    report["git_root"] = root
    if not root:
        report["ok"] = False
        report["error"] = "not inside a git repository"
        print(json.dumps(report, indent=2))
        return

    contract_path = os.path.join(root, "docs", "agent-workflow", "CONTRACT.md")
    version_found = None
    if os.path.isfile(contract_path):
        with open(contract_path, encoding="utf-8") as f:
            m = re.search(r"\*\*Version:\*\*\s*([0-9.]+)", f.read())
            if m:
                version_found = m.group(1)
    report["contract_file_found"] = os.path.isfile(contract_path)
    report["contract_version_found"] = version_found

    base = task_root(root)
    report["task_dir"] = os.path.relpath(base, root)
    report["task_dir_resolution"] = (
        "override" if os.path.isfile(os.path.join(root, ".agent-workflow-location")) else "default"
    )

    active = find_active_task(base)
    report["active_task_id"] = active.get("task_id") if active else None
    report["active_task_stale"] = is_stale(active) if active else None

    events_valid = None
    if active:
        tdir = task_dir_for(base, active["task_id"])
        events_path = os.path.join(tdir, "events.jsonl")
        events_valid = True
        prev_ts = ""
        if os.path.isfile(events_path):
            try:
                with open(events_path, encoding="utf-8") as f:
                    for line in f:
                        if not line.strip():
                            continue
                        e = json.loads(line)
                        if e.get("task_id") != active["task_id"]:
                            events_valid = False
                        if e.get("timestamp", "") < prev_ts:
                            events_valid = False
                        prev_ts = e.get("timestamp", "")
            except Exception:
                events_valid = False
    report["events_sequence_valid"] = events_valid

    # Privacy self-test in an isolated temp dir — never touches the real task.
    privacy_ok = None
    with tempfile.TemporaryDirectory() as td:
        try:
            subprocess.run(["git", "init", "-q"], cwd=td, check=True, capture_output=True)
            subprocess.run(["git", "config", "user.email", "doctor@local"], cwd=td, check=True, capture_output=True)
            subprocess.run(["git", "config", "user.name", "doctor"], cwd=td, check=True, capture_output=True)
            script = os.path.abspath(__file__)
            secret = "sk-THISISASYNTHETICSECRETVALUE1234"
            r = subprocess.run(
                [sys.executable, script, "init-task",
                 json.dumps({"title": "doctor-test", "goal": "smoke test", "next_action": "n/a"})],
                cwd=td, capture_output=True, text=True,
            )
            r2 = subprocess.run(
                [sys.executable, script, "append-event",
                 json.dumps({"type": "assessment", "summary": secret, "rationale": "doctor self-test"})],
                cwd=td, capture_output=True, text=True,
            )
            privacy_ok = (r.returncode == 0 and r2.returncode != 0 and secret not in (r2.stdout + r2.stderr))
        except Exception:
            privacy_ok = False
    report["privacy_rejection_self_test_passed"] = privacy_ok

    # Write/read/refresh smoke test, isolated temp dir.
    smoke_ok = None
    with tempfile.TemporaryDirectory() as td:
        try:
            subprocess.run(["git", "init", "-q"], cwd=td, check=True, capture_output=True)
            subprocess.run(["git", "config", "user.email", "doctor@local"], cwd=td, check=True, capture_output=True)
            subprocess.run(["git", "config", "user.name", "doctor"], cwd=td, check=True, capture_output=True)
            script = os.path.abspath(__file__)
            r1 = subprocess.run(
                [sys.executable, script, "init-task",
                 json.dumps({"title": "smoke", "goal": "smoke", "next_action": "go"})],
                cwd=td, capture_output=True, text=True,
            )
            r2 = subprocess.run(
                [sys.executable, script, "set-task", json.dumps({"phase": "implementation"})],
                cwd=td, capture_output=True, text=True,
            )
            r3 = subprocess.run([sys.executable, script, "read-active"], cwd=td, capture_output=True, text=True)
            smoke_ok = r1.returncode == 0 and r2.returncode == 0 and r3.returncode == 0 and "smoke" in r3.stdout
        except Exception:
            smoke_ok = False
    report["write_read_refresh_smoke_test_passed"] = smoke_ok

    settings_path = os.path.join(os.path.expanduser("~"), ".claude", "settings.json")
    hook_names = [
        "task-record-session.sh", "task-record-prompt.sh",
        "task-record-post.sh", "task-record-stop.sh",
    ]
    hook_health = {}
    if os.path.isfile(settings_path):
        content = open(settings_path, encoding="utf-8").read()
        for h in hook_names:
            hook_health[h] = h in content
    else:
        hook_health = {h: None for h in hook_names}
    report["hook_health"] = hook_health

    report["ok"] = bool(
        report["contract_file_found"]
        and (events_valid is not False)
        and privacy_ok
        and smoke_ok
    )
    print(json.dumps(report, indent=2))


def main():
    import argparse
    parser = argparse.ArgumentParser(prog="task_record.py")
    parser.add_argument("--task-id", dest="task_id", default=None)
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("resolve")
    sub.add_parser("read-active")
    for name in ("init-task", "set-task", "append-event"):
        p = sub.add_parser(name)
        p.add_argument("json")
    p = sub.add_parser("finalize")
    p.add_argument("json", nargs="?", default="{}")
    sub.add_parser("doctor")

    args = parser.parse_args()
    handlers = {
        "resolve": cmd_resolve,
        "read-active": cmd_read_active,
        "init-task": cmd_init_task,
        "set-task": cmd_set_task,
        "append-event": cmd_append_event,
        "finalize": cmd_finalize,
        "doctor": cmd_doctor,
    }
    try:
        handlers[args.cmd](args)
    except RejectError as e:
        die(str(e))
    except json.JSONDecodeError:
        die("rejected: invalid JSON payload")
    except Exception:
        die("rejected: internal error")


if __name__ == "__main__":
    main()

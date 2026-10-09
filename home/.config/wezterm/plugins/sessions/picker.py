#!/usr/bin/env python3
"""Small fzf frontend. WezTerm owns session state and all workspace mutations."""
import base64
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import time
import uuid


def environment():
    env = os.environ.copy()
    # User-wide preview commands/bindings must not change this application's UI.
    for key in list(env):
        if key.startswith("FZF_DEFAULT_") or key == "FZF_API_KEY":
            env.pop(key)
    return env


def valid_name(value):
    value = value.strip()
    if not value or len(value.encode()) > 120 or any(ord(c) < 32 or ord(c) == 127 for c in value):
        raise ValueError("Use a name of 1–120 bytes, without control characters.")
    return value


def colored(text, rgb):
    return f"\033[38;2;{rgb}m{text}\033[39m"


STATUS_STYLE = {
    "active": ("\uf111", "158;206;106"),
    "running": ("\uf10c", "122;162;247"),
    "saved": ("\uf187", "119;128;160"),
}


def make_rows(sessions, query, fzf):
    query = query.strip()
    names = [s["name"] for s in sessions]
    matches = names
    if query and names:
        result = subprocess.run(
            [fzf, "--filter", query, "--scheme=default", "+x", "-i"],
            input="\n".join(names), text=True, capture_output=True, env=environment(),
        )
        if result.returncode not in (0, 1):
            raise RuntimeError(result.stderr.strip())
        matches = result.stdout.splitlines()
    by_name = {s["name"]: s for s in sessions}
    rows = []
    for name in matches:
        item = by_name[name]
        status = item["status"]
        icon, color = STATUS_STYLE[status]
        label = f"{colored(icon, color)}  {name:<28}  {colored(status, color)}"
        rows.append("open\t" + json.dumps(name, ensure_ascii=False) + "\t" + label)
    if query and query not in names:
        try:
            valid_name(query)
            icon = colored("\uf067", "192;132;252")
            rows.append("create\t" + json.dumps(query, ensure_ascii=False) + f"\t{icon}  Create session “{query}”")
        except ValueError:
            pass
    if not rows:
        rows.append("hint\t\"\"\tType a name to create your first session")
    return "\n".join(rows) + "\n"


def style():
    return [
        "--ansi", "--layout=reverse", "--border=none", "--margin=2,4", "--padding=1,2",
        "--info=hidden", "--no-separator", "--no-scrollbar", "--pointer=›", "--gutter= ",
        "--highlight-line", "--header-first", "--prompt=› ",
        "--color=bg:-1,fg:#a9b1d6,bg+:#24283b,fg+:#c0caf5,hl:#c084fc,hl+:#c084fc,pointer:#c084fc,prompt:#c084fc,header:#c0caf5,footer:#565f89,gutter:-1",
        "--footer-border=none",
    ]


def run_fzf(fzf, args, data=""):
    result = subprocess.run([fzf, *style(), *args], input=data, text=True,
                            stdout=subprocess.PIPE, env=environment())
    if result.returncode in (1, 130):
        return None
    if result.returncode:
        raise RuntimeError(f"fzf exited with status {result.returncode}")
    return result.stdout.splitlines()


def ask_name(fzf, old, error=""):
    result = run_fzf(fzf, ["--disabled", "--query", old,
        "--header", error or "Rename session", "--footer=enter save · esc cancel",
        "--bind=enter:print-query"])
    return result[0] if result else None


def confirm_delete(fzf, name):
    result = run_fzf(fzf, ["--header", f"Delete “{name}”?\nRunning terminals will be closed and its saved layout removed.",
        "--footer=enter choose · esc cancel", "--no-input", "--no-sort"],
        "Cancel\nDelete session\n")
    return result == ["Delete session"]


def request(directory, action, **values):
    request_id = uuid.uuid4().hex
    payload = dict(id=request_id, action=action, socket=os.environ.get("WEZTERM_UNIX_SOCKET"), **values)
    encoded = base64.b64encode(json.dumps(payload).encode()).decode()
    sys.stdout.write(f"\033]1337;SetUserVar=SESSION_MANAGER={encoded}\007")
    sys.stdout.flush()
    reply = directory / "reply.json"
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        try:
            response = json.loads(reply.read_text())
            if response.get("id") == request_id:
                if response.get("error"):
                    raise RuntimeError(response["error"])
                return response
        except (FileNotFoundError, json.JSONDecodeError):
            pass
        time.sleep(0.03)
    raise RuntimeError("WezTerm did not respond. Close this tab and reopen the picker.")


def picker(directory, fzf):
    command = shlex.join([sys.executable, str(Path(__file__).resolve()), "rows", str(directory), fzf])
    query, message = "", ""
    while True:
        sessions = json.loads((directory / "sessions.json").read_text())
        result = run_fzf(fzf, [
            "--disabled", "--delimiter=\t", "--with-nth=3..", "--no-sort", "--gap=1", "--gap-line=",
            "--header", message or "Sessions", "--ghost=Find or name a session",
            "--footer=enter open/create · ctrl-r rename · ctrl-x delete · esc close",
            "--print-query", "--expect=enter,ctrl-r,ctrl-x", "--query", query,
            "--bind", "change:reload-sync(" + command + ")",
        ], make_rows(sessions, query, fzf))
        message = ""
        if result is None:
            request(directory, "cancel")
            return
        if len(result) < 3:
            continue
        query, key, row = result[:3]
        # A very fast Enter can arrive before a reload has replaced the old
        # list. Never act on a selection from a different query.
        # fzf strips display ANSI codes from accepted rows; compare only the
        # hidden action/name fields, which are independent of presentation.
        if row.split("\t", 2)[:2] not in [
            candidate.split("\t", 2)[:2]
            for candidate in make_rows(sessions, query, fzf).splitlines()
        ]:
            continue
        kind, encoded, _ = row.split("\t", 2)
        name = json.loads(encoded)
        if kind == "hint":
            continue
        try:
            if key == "enter":
                request(directory, "open", name=valid_name(name), create=kind == "create")
                return
            if kind != "open":
                continue
            if key == "ctrl-r":
                new = ask_name(fzf, name)
                if new is not None:
                    request(directory, "rename", name=name, new_name=valid_name(new))
                    query = ""
            elif key == "ctrl-x" and confirm_delete(fzf, name):
                response = request(directory, "delete", name=name)
                if response.get("close"):
                    return
                query = ""
        except (ValueError, RuntimeError) as exc:
            message = str(exc)


def main():
    mode, directory, fzf = sys.argv[1:]
    directory = Path(directory)
    if mode == "rows":
        sessions = json.loads((directory / "sessions.json").read_text())
        print(make_rows(sessions, os.environ.get("FZF_QUERY", ""), fzf), end="")
        return
    try:
        picker(directory, fzf)
    except (RuntimeError, OSError) as exc:
        print(f"\nSession picker: {exc}")
        input("Press Enter to close…")
    finally:
        for name in ("sessions.json", "reply.json"):
            (directory / name).unlink(missing_ok=True)
        try:
            directory.rmdir()
        except OSError:
            pass


if __name__ == "__main__":
    main()

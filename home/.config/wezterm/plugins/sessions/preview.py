#!/usr/bin/env python3
"""Read-only session preview. Terminal contents are never saved to disk."""
import json
import os
from pathlib import Path
import subprocess
import sys

def safe_text(value):
    return "".join(c for c in str(value) if c in "\n\t" or (ord(c) >= 32 and not 127 <= ord(c) <= 159))


def pane_directories(tree):
    if not tree:
        return []
    return ([tree.get("cwd") or "Unknown directory"]
            + pane_directories(tree.get("right"))
            + pane_directories(tree.get("bottom")))


def layout_lines(session):
    windows = (session.get("snapshot") or {}).get("window_states", [])
    if not windows:
        return ["No saved layout available."]
    lines = []
    home = str(Path.home())
    for index, window in enumerate(windows, 1):
        lines.append(f"Window {index}")
        for number, tab in enumerate(window.get("tabs", []), 1):
            title = tab.get("title") or f"Tab {number}"
            lines.append(f"  {title}")
            for cwd in pane_directories(tab.get("pane_tree")):
                if cwd == home or cwd.startswith(home + "/"):
                    cwd = "~" + cwd[len(home):]
                lines.append(f"    └ {cwd}")
        lines.append("")
    return lines


def terminal_text(name):
    # Use the inherited mux socket, never focus or activate the target pane.
    command = [os.environ.get("SESSION_WEZTERM", "wezterm"), "cli", "--no-auto-start"]
    def run(args):
        return subprocess.run(command + args, capture_output=True, text=True,
                              timeout=2, check=True).stdout
    try:
        panes = [p for p in json.loads(run(["list", "--format=json"]))
                 if p.get("workspace") == name
                 and str(p["pane_id"]) != os.environ.get("WEZTERM_PANE")]
        if not panes:
            return None
        panes.sort(key=lambda p: (str(p["pane_id"]) != os.environ.get("SESSION_ORIGIN_PANE"),
                                  not p.get("is_active", False)))
        pane = panes[0]
        text = run(["get-text", "--pane-id", str(pane["pane_id"])])
        return [f"Terminal · {pane.get('title') or 'pane'}", "", *text.rstrip().splitlines()]
    except (OSError, subprocess.SubprocessError, ValueError, KeyError):
        return None


def preview_lines(sessions, kind, name):
    if kind == "create":
        return [name, "", "New session", "Enter to create it."]
    if kind != "open":
        return ["Select a session to preview."]
    session = next((s for s in sessions if s["name"] == name), None)
    if session is None:
        return ["Session no longer available."]
    lines = [name, session["status"], ""]
    if session["status"] != "saved":
        live = terminal_text(name)
        if live is not None:
            return lines + live
        lines += ["Terminal unavailable; saved layout:", ""]
    else:
        lines += ["Saved layout · restores fresh shells", ""]
    return lines + layout_lines(session)


def main():
    directory, kind, encoded = sys.argv[1:]
    try:
        sessions = json.loads((Path(directory) / "sessions.json").read_text())
        lines = preview_lines(sessions, kind, json.loads(encoded))
        print(safe_text("\n".join(lines)))
    except (OSError, ValueError):
        print("Preview unavailable. Select the session again to retry.")


if __name__ == "__main__":
    main()

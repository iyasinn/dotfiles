#!/usr/bin/env python3
"""Small fzf frontend. WezTerm owns session state and all workspace mutations."""
import base64
import json
import os
from pathlib import Path
import shlex
import shutil
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


def picker_size(height=18, width=84):
    columns, lines = shutil.get_terminal_size((120, 36))
    return columns, lines, max(0, (columns - width) // 2), max(0, (lines - height) // 2)


ART_PATH = os.environ.get("SESSION_ART_PATH", "")
ART_HEIGHT = int(os.environ.get("SESSION_ART_HEIGHT", "10"))


def render_art(height=None, width=None, stream=None):
    # Send the GIF once; WezTerm decodes and animates the original image frames.
    # Emit the iTerm image sequence directly: imgcat's terminal queries can hang
    # inside fzf's preview subprocess, which has piped output rather than a TTY.
    if not ART_PATH:
        return
    path = Path(ART_PATH)
    payload = base64.b64encode(path.read_bytes()).decode("ascii")
    if width is None:
        width = max(1, int(os.environ.get("FZF_PREVIEW_COLUMNS", "74")))
    if height is None:
        height = max(1, int(os.environ.get("FZF_PREVIEW_LINES", str(ART_HEIGHT))))
    stream = stream or sys.stdout
    stream.write(f"\033]1337;File=inline=1;width={width};height={height};preserveAspectRatio=1:{payload}\007\n")
    stream.flush()


def animation_options():
    columns, lines, horizontal, _ = picker_size()
    if (not ART_PATH
            or lines < int(os.environ.get("SESSION_ART_MIN_ROWS", "26"))
            or columns - 2 * horizontal - 10 < int(os.environ.get("SESSION_ART_MIN_COLUMNS", "30"))):
        return []
    command = shlex.join([sys.executable, str(Path(__file__).resolve()), "art"])
    return ["--preview", "exec " + command,
            f"--preview-window=up,{ART_HEIGHT},border-none,noinfo"]


def style(height=18, width=84):
    _, _, horizontal, vertical = picker_size(height, width)
    return [
        "--ansi", "--layout=reverse", "--border=rounded", "--border-label= Sessions ",
        f"--margin={vertical},{horizontal}", "--padding=1,2",
        "--info=hidden", "--no-separator", "--no-scrollbar", "--pointer=›", "--gutter= ",
        "--highlight-line", "--header-first", "--prompt=› ",
        "--input-border=rounded",
        "--color=bg:-1,fg:#a9b1d6,bg+:#24283b,fg+:#c0caf5,hl:#c084fc,hl+:#c084fc,pointer:#c084fc,prompt:#c084fc,header:#c0caf5,footer:#565f89,gutter:-1,preview-bg:-1,input-border:#565f89,border:#7aa2f7,label:#c084fc",
        "--footer-border=none",
    ]


def run_with_art_header(fzf, args, data, height, width):
    # fzf treats inline images as full-height previews. Give the island its own
    # terminal rows above a height-limited fzf so the right preview remains text.
    columns, rows, horizontal, _ = picker_size(height, width)
    art_height = min(6, ART_HEIGHT)
    # The bundled GIF has a 4:1 canvas; terminal cells are roughly twice as tall
    # as they are wide. Center its displayed canvas rather than its width limit.
    art_width = min(max(1, columns - 2 * horizontal), art_height * 8)
    art_left = max(0, (columns - art_width) // 2)
    finder_height = max(8, min(height - art_height, rows - art_height - 2))
    vertical = max(0, (rows - finder_height - art_height) // 2)
    options = style(finder_height, width)
    options = [arg for arg in options if not arg.startswith("--margin=")]
    options += [f"--margin=0,{horizontal}", f"--height={finder_height}"]
    with open("/dev/tty", "w") as terminal:
        terminal.write("\033[?1049h\033[2J")
        try:
            terminal.write(f"\033[{vertical + 1};{art_left + 1}H")
            render_art(height=art_height, width=art_width, stream=terminal)
            terminal.write(f"\033[{vertical + art_height + 1};1H")
            terminal.flush()
            return subprocess.run([fzf, *options, *args], input=data, text=True,
                                  stdout=subprocess.PIPE, env=environment())
        finally:
            terminal.write("\033[?1049l")
            terminal.flush()


def run_fzf(fzf, args, data=""):
    # One row per session, plus borders, padding, search, footer, and art.
    # Cap the list height so larger collections scroll inside a compact box.
    header = args[args.index("--header") + 1] if "--header" in args else ""
    footer = next((arg.partition("=")[2] for arg in args if arg.startswith("--footer=")), "")
    height = 9 + min(6, max(1, len(data.splitlines()))) + len(header.splitlines())
    height += max(0, len(footer.splitlines()) - 1)
    if "--preview" in args:
        height += ART_HEIGHT
    width = 120 if "--preview-label= Session preview " in args else 84
    if width == 120 and animation_options():
        result = run_with_art_header(fzf, args, data, height, width)
    else:
        result = subprocess.run([fzf, *style(height, width), *args], input=data, text=True,
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
    preview_visible, position = False, 1
    preview_command = shlex.join([sys.executable, str(Path(__file__).with_name("preview.py")), str(directory)])
    while True:
        sessions = json.loads((directory / "sessions.json").read_text())
        result = run_fzf(fzf, [
            "--disabled", "--delimiter=\t", "--with-nth=3..", "--no-sort",
            "--header", message, "--ghost=Find or name a session",
            *(["--preview", preview_command + " {1} {2}",
               "--preview-window=right,45%,border-rounded,noinfo",
               "--preview-label= Session preview "] if preview_visible else animation_options()),
            "--footer=enter open/create · ctrl-r rename · ctrl-x delete\nctrl-t preview · esc close",
            f"--bind=start:pos({position})",
            "--print-query", "--expect=enter,ctrl-r,ctrl-x,ctrl-t", "--query", query,
            "--bind", "change:reload-sync(" + command + ")",
        ], make_rows(sessions, query, fzf))
        message = ""
        if result is None:
            request(directory, "cancel")
            return
        if len(result) < 3:
            continue
        query, key, row = result[:3]
        if key == "ctrl-t":
            preview_visible = not preview_visible
            candidates = make_rows(sessions, query, fzf).splitlines()
            identity = row.split("\t", 2)[:2]
            position = next((i for i, candidate in enumerate(candidates, 1)
                             if candidate.split("\t", 2)[:2] == identity), 1)
            continue
        position = 1
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
    if sys.argv[1:] == ["art"]:
        render_art()
        return
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

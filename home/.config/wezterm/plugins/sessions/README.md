# Sessions

A local WezTerm session manager with a minimal fzf interface. Requires Python 3,
fzf 0.74 or newer, and the existing `plugins.resurrect` layout engine.

- **Ctrl-A, S:** open the picker over the current tab using a zoomed temporary pane.
- **Enter:** switch to the highlighted session, restore a saved one, or create
  the explicitly labeled new session. New sessions start in the originating
  pane's directory. Remote panes currently use the local home directory.
- **Ctrl-R:** rename the highlighted session, with its existing name prefilled.
- **Ctrl-X:** delete the highlighted session after confirmation. This terminates
  its running terminals and removes its saved layout. Cancel is selected first.
- **Esc:** return to the originating pane and its previous zoom state. In a rename or delete prompt, return
  to the picker instead.

Search uses fzf's case-insensitive fuzzy matching. A nonempty query without an
exact existing name gets an explicit Create row below matching sessions. Session
names are case-sensitive, may contain spaces and punctuation, and are limited
to 120 UTF-8 bytes. Names are JSON keys, never filenames or shell commands.

Sessions are WezTerm workspaces. Switching preserves live processes. Layouts
are saved every 15 seconds and when opening the picker or switching sessions.
After restarting WezTerm, open the picker and select a saved session to restore
its windows, tabs, splits, and directories. Restore starts fresh shells; it does
not restart prior commands or restore process memory or scrollback. The latest
changes can be lost if WezTerm exits before the next save. Missing directories
or unavailable remote domains can prevent restoration.

State lives at `$XDG_STATE_HOME/wezterm/sessions/index.json`, defaulting to
`~/.local/state/wezterm/sessions/index.json`. Writes replace the file atomically.
While the picker is open, snapshots retain the original tab layout. Closing the
picker removes its temporary pane and restores focus and the previous zoom state. Existing Resurrect save
files are left intact; they are not imported into this manager.

The manager uses Resurrect's layout capture/restore functions without its
separate setup, autosave, or keybindings. Keep `sessions = true` and
`resurrect = false` in `plugins/init.lua`. Quick Select is now **Ctrl-A, Q**.

Lua owns workspace mutations and persistence. The Python frontend sends OSC
requests accepted only from the registered picker pane and waits for an atomic
JSON acknowledgment. Deletion targets exact pane IDs through the picker's own
WezTerm socket, independent of GUI focus.

Run picker regression tests:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s plugins/sessions -p 'test_*.py'
```

# Sessions

A WezTerm session manager for the local background mux server with a minimal fzf interface. Requires Python 3,
fzf 0.74 or newer, and the existing `plugins.resurrect` layout engine.

The picker opens in a compact centered box with a bordered search field.
For mux terminals, it uses a temporary tab in the current window; for old local terminals,
it uses a zoomed temporary split. Its
height follows the session count (up to six visible rows, then scrolling).
Rename and delete prompts use the same centered styling. Artwork is enabled in this nightly configuration. Set `enabled = false` in
`art.lua` to use plain text if native image-rendering errors recur.

Artwork is configured in `art.lua`. After changing it, reload with
Cmd+Shift+R and reopen the picker. Missing, unreadable,
oversized, or unrecognized GIF files fall back to text. Input is limited to
2 MiB and a one-megapixel canvas; these are resource guards, not full decoder
validation or a guarantee against WezTerm rendering bugs.

When enabled, the image is emitted once per picker screen, outside fzf's
selection-driven preview. Search and moving between sessions do not resend it.
Reopening the picker or toggling its text preview creates a new screen and
emits it again. Small terminals omit artwork. No runtime downloads or temporary
image files are used. The bundled artwork remains unchanged.

The animation is the [floating island GIF selected by the user](https://64.media.tumblr.com/0f5eefb51abeeb07aa525a83e733b408/tumblr_nh7vzpNNJX1t63sglo1_500.gifv).
The source URL does not identify the artist.

### Native image cache failures

`frames.current_frame.lease.get_data: Io error in BlobLease: No such file or directory`
means WezTerm could not read an internal cached blob. Keeping the original GIF
on disk does not keep that blob alive. Lua `pcall` and Python exception handling
cannot intercept this GUI renderer failure, and reloading config does not repair
already cached images.

The [WezTerm maintainer suggested testing a persistent TMPDIR](https://github.com/wezterm/wezterm/discussions/5329)
for the same missing-blob error, because system temporary-file cleanup may be
responsible. This is a hypothesis, not a verified diagnosis for this setup.
If testing native GIFs again:

1. Start a separate test GUI with a private persistent `TMPDIR` set **before**
   launching the WezTerm executable. Changing a pane's environment or
   `set_environment_variables` only affects child processes, not the running GUI.
2. Keep that directory out of automated cleanup while the GUI is running.
   Never delete WezTerm's live blob cache as a recovery action.
3. Test repeated picker open/close, search, preview toggles, config reload,
   and sleep/wake. Inspect the GUI log for `BlobLease` and `paint_pass failed`.
4. Disable artwork if these errors recur. The enabled setting is a preference,
   not a claim that native rendering is free of bugs.

This configuration does not alter the current GUI's cache location, clear
scrollback, or restart any sessions. Disabling artwork prevents new picker image
output; it cannot repair an image already retained by the running GUI.

- **Ctrl-A, S:** open the picker.
- **Ctrl-A, D:** detach the persistent mux domain without stopping its programs.
  Close the picker first; local-only panes cannot be detached.
- **Enter:** switch to the highlighted session, restore a saved one, or create
  the explicitly labeled new session. New sessions start in the originating
  pane's directory. Local mux panes retain their directory; other remote domains use the local home directory.
- **Ctrl-T:** toggle the bordered session preview on the right. It starts off;
  optional artwork stays above the picker. Search and selection survive toggling.
- **Ctrl-N / Ctrl-P:** move to the next / previous session.
- **Ctrl-R:** rename the highlighted session, with its existing name prefilled.
- **Ctrl-X:** delete the highlighted session after confirmation: press `y` to delete,
  `n` or Esc cancels. This terminates its running terminals and removes its saved layout.
- **Esc:** return to the originating pane and its previous zoom state. In a rename or delete prompt, return
  to the picker instead.

The preview shows a read-only snapshot of one terminal in a running session,
preferring the originating pane or an active pane. It refreshes when selection
changes or the preview is reopened; it is not a continuously updating terminal.
Saved sessions show their windows, tabs, and pane directories instead. If a live
pane cannot be read, the preview falls back to the saved layout. Terminal contents
are read on demand and never added to the saved session state. fzf has one preview
area; optional artwork always uses separate terminal rows above the picker.
The renderer lives separately in `preview.py`.

Search uses fzf's case-insensitive fuzzy matching. A nonempty query without an
exact existing name gets an explicit Create row below matching sessions. Session
names are case-sensitive, may contain spaces and punctuation, and are limited
to 120 UTF-8 bytes. Names are JSON keys, never filenames or shell commands.

Sessions are WezTerm workspaces, shared by all normal windows through the same
mux server and session picker. `Cmd+N` adds a window to the current session.
`Cmd+Q` closes the GUI after confirmation while server-owned sessions keep running.
Switching preserves live processes. Layouts
are autosaved on status updates with a 15-second interval while WezTerm is running,
and when opening the picker or switching sessions. Rename and delete operations
persist their changes immediately.
After restarting the GUI, reconnect with `wezterm connect unix` (also the default
on normal launch) to resume server-owned processes. After a reboot or server
failure, select a saved session in the picker to restore its windows, tabs,
splits, and directories into the new server. Restore starts fresh shells; it does
not restart prior commands or restore process memory, scrollback, or unsaved editor
content. Shell history is managed separately by your shell. The latest
changes can be lost if WezTerm exits before the next save. Missing directories
or unavailable remote domains can prevent restoration.

State lives at `$XDG_STATE_HOME/wezterm/sessions/index.json`, defaulting to
`~/.local/state/wezterm/sessions/index.json`. State is plaintext JSON. Writes replace the file atomically
and are capped at 2 MiB; oversized saves are rejected without replacing the
previous state. An unreadable file stops saving instead of resetting state.

On the first capture of a fresh server or local GUI session,
a running workspace that shares a saved name is renamed to `name (current)`
(with a numeric suffix if needed). Its running programs stay intact. Select the
original name in the picker to restore the saved layout. This prevents a fresh
`default` workspace from replacing the previous layout before you can restore it.
Snapshots record the server-instance token. Reconnecting to that same server
preserves names and running programs; a new server is treated as a fresh start.
Local terminals retain the original collision protection.

Restores use a copy in a separate workspace and verify window, tab, and pane
counts before assigning the saved name. Incomplete restores retain an
`(incomplete restore)` name and are excluded from autosave. Close those temporary
workspaces before retrying; the original saved layout remains available.
While the picker is open, snapshots retain the original tab layout. Closing the
picker removes its temporary pane and restores focus and the previous zoom state. Existing Resurrect save
files are left intact; they are not imported into this manager.

The GUI owns the picker and layout snapshots. The mux server runs a separate
minimal config, so it never starts picker timers or GUI plugins.

The manager uses Resurrect's layout capture/restore functions without its
separate setup, autosave, or keybindings. Keep `sessions = true` and
`resurrect = false` in `plugins/init.lua`. The latter disables standalone setup;
it does not disable or remove the engine dependency. Keep the Resurrect checkout
installed while Sessions is enabled. Quick Select is **Ctrl-A, Q**.

Lua owns workspace mutations and persistence. The Python frontend sends OSC
requests accepted only from the registered picker pane and waits for an atomic
JSON acknowledgment. Deletion targets exact pane IDs through the picker's own
WezTerm socket, independent of GUI focus.

Run picker regression tests:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s plugins/sessions -p 'test_*.py'
```

Lua recovery regressions live in `test_recovery.lua`; run them with WezTerm's Lua runtime and an isolated temporary state directory.

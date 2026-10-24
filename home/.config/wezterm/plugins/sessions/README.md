# Sessions

A local WezTerm session manager with a minimal fzf interface. Requires Python 3,
fzf 0.74 or newer, and the existing `plugins.resurrect` layout engine.

The picker opens in a compact centered box with a bordered search field. Its
height follows the session count (up to six visible rows, then scrolling).
Rename and delete prompts use the same centered styling. Artwork is off by default:
plain text avoids the native image cache path that previously failed.

Optional artwork is configured in `art.lua`. Set `enabled = true` to opt in,
then reload with Cmd+Shift+R and reopen the picker. Missing, unreadable,
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
4. Keep native images opt-in until that test is stable. Text/glyph animations
   are the preferred default for future visual plugins.

This configuration does not alter the current GUI's cache location, clear
scrollback, or restart any sessions. It prevents new picker image output by
default; it cannot repair an image already retained by the running GUI.

- **Ctrl-A, S:** open the picker over the current tab using a zoomed temporary pane.
- **Enter:** switch to the highlighted session, restore a saved one, or create
  the explicitly labeled new session. New sessions start in the originating
  pane's directory. Remote panes currently use the local home directory.
- **Ctrl-T:** toggle the bordered session preview on the right. It starts off;
  optional artwork stays above the picker. Search and selection survive toggling.
- **Ctrl-P:** re-read and resend enabled artwork, rebuilding only the picker
  screen while preserving the search, selection, and preview toggle. This is
  an experimental recovery attempt, not a WezTerm cache reset. When artwork is
  disabled or unavailable, the picker explains why it cannot resend it.
- **Ctrl-R:** rename the highlighted session, with its existing name prefilled.
- **Ctrl-X:** delete the highlighted session after confirmation. This terminates
  its running terminals and removes its saved layout. Cancel is selected first.
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

Sessions are WezTerm workspaces. Switching preserves live processes. Layouts
are autosaved on status updates with a 15-second interval while WezTerm is running,
and when opening the picker or switching sessions. Rename and delete operations
persist their changes immediately.
After restarting WezTerm, open the picker and select a saved session to restore
its windows, tabs, splits, and directories. Restore starts fresh shells; it does
not restart prior commands or restore process memory, scrollback, or unsaved editor
content. Shell history is managed separately by your shell. The latest
changes can be lost if WezTerm exits before the next save. Missing directories
or unavailable remote domains can prevent restoration.

State lives at `$XDG_STATE_HOME/wezterm/sessions/index.json`, defaulting to
`~/.local/state/wezterm/sessions/index.json`. State is plaintext JSON. Writes replace
the latest file atomically; no rotating historical backups are kept.
While the picker is open, snapshots retain the original tab layout. Closing the
picker removes its temporary pane and restores focus and the previous zoom state. Existing Resurrect save
files are left intact; they are not imported into this manager.

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

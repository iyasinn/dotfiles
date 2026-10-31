# WezTerm plugins

Plugin switches live in `plugins/init.lua`. Change a switch, then press
`Cmd+Shift+R` to reload the configuration.

## Persistent sessions

WezTerm now connects to a local background mux server automatically. It starts
on demand; no login service is installed. The GUI settings live in
`plugins/persistent.lua`; the lightweight server config is `mux-server.lua`.
The socket and server-instance marker live in `$XDG_STATE_HOME/wezterm`
(default `~/.local/state/wezterm`).

The server removes inherited `NO_COLOR` at startup so interactive apps can use
colors even if the server was launched by an automation tool. This requires a
server restart to affect future shells; reloading the GUI does not change the
running server's environment. In an existing shell, run `unset NO_COLOR`, then
relaunch the affected app. Do not stop the server while it has work to preserve.

- **Start/reconnect:** open WezTerm normally, or run `wezterm connect unix`.
- **Session picker:** `Ctrl+A`, then `s` accesses the same named sessions from every
  normal window. A session can contain multiple windows, tabs, and splits.
- **Quit:** `Cmd+Q` closes the GUI after confirmation. Server-owned sessions and
  their running programs remain available when you reopen WezTerm.
- **Detach safely:** `Ctrl+A`, then `d`. This disconnects all windows in the
  persistent domain while leaving their programs running. Close the picker first.
- **New window:** `Cmd+N` creates a window in the current session. Tabs and splits follow the
  current pane's domain.
- **End work:** close tabs/panes or delete a session; these still terminate programs.
- **Existing terminals:** a config reload cannot migrate old GUI-owned processes.
  Use `Cmd+N` for new work in the shared server; keep old terminals until you finish them.
- **Reboot/server failure:** running processes stop. Use the saved-layout picker to
  restore fresh shells afterward. Session switching/GUI restarts while the server
  lives reconnect to existing programs instead.

The picker opens in a temporary tab in the current window when used from a mux terminal. This
keeps its UI and CLI pane IDs on the GUI side and avoids changing server splits.
Existing local terminals retain the original zoomed-pane picker.

## Enabled plugins and dependencies

- **Sessions:** local session picker and persistence, using Python 3, fzf 0.74
  or newer, and the Resurrect layout engine.
- **Smart Splits:** navigation and resizing across WezTerm and Neovim panes.
- **Tabline:** workspace, tab index, process or custom tab title, zoom status,
  and time. It preserves the main configuration's padding and tab width.
- **Command Picker:** searchable commands and shortcuts. Loaded last so it can
  discover bindings added by other plugins.

Keep `sessions = true` and `resurrect = false` for the current setup.
`resurrect = false` disables Resurrect's standalone setup, not the engine that
Sessions needs. Sessions loads that engine directly for layout capture and
restoration; Sessions owns its own autosave, state file, and picker bindings.
Do not remove the Resurrect checkout while Sessions is enabled.

## Shortcuts

| Feature | Shortcut | Action |
| --- | --- | --- |
| Sessions | `Ctrl+A`, then `s` | Open the session picker |
| Persistence | `Ctrl+A`, then `d` | Detach without stopping programs |
| Picker | `Enter` | Open, restore, or create the selected session |
| Picker | `Ctrl+T` | Toggle the session preview on the right |
| Picker | `Ctrl+N` / `Ctrl+P` | Move to the next / previous session |
| Picker | `Ctrl+R` | Rename the selected session |
| Picker | `Ctrl+X` | Delete the session (press `y` to confirm, `n` or `Esc` cancels) |
| Picker | `Esc` | Close the picker; cancel a rename/delete prompt |
| Smart Splits | `Ctrl+H/J/K/L` | Move between WezTerm and Neovim splits |
| Smart Splits | `Cmd+H/J/K/L` | Resize splits on macOS |
| Command Picker | `Ctrl+A`, then `Space` | Search commands and shortcuts |
| Quick Select | `Ctrl+A`, then `q` | Select detected text |
| Configuration | `Cmd+Shift+R` | Reload WezTerm configuration |

Sessions replaces the old Sessionizer menu. Its former create, project-picker,
delete-state, and help shortcuts are no longer configured. Resurrect's
standalone shortcuts are not enabled in this setup.

## What Sessions saves

While WezTerm is running, Sessions autosaves layouts on status updates with a
15-second interval. It also saves when opening the picker or switching sessions;
rename and delete operations persist their changes immediately.

Saved state includes session names, windows, tabs, splits, and working
directories. Switching between live sessions preserves their running programs.
Restoring after the mux server stops rebuilds the layout with fresh shells: it does not
resume programs, recover unsaved editor content, or restore terminal scrollback.
Shell history is managed separately by your shell.

State is stored as plaintext JSON at
`$XDG_STATE_HOME/wezterm/sessions/index.json`, defaulting to
`~/.local/state/wezterm/sessions/index.json`. Each save atomically replaces the
latest state, with a 2 MiB limit. Corrupt state stops saving instead of
resetting. Fresh-server/startup name collisions preserve live work under a `(current)` name;
select the original name to restore its saved layout. Reconnecting to the same
server preserves workspace names. Incomplete restores do not
overwrite the original save. Changes since the last
successful save can be lost after an unexpected quit.

Session names are user-chosen, not automatically derived from project paths.
Deleting a session closes its running terminals after confirmation and removes
its saved layout. Existing standalone Resurrect saves are not imported or deleted.

See [Sessions documentation](plugins/sessions/README.md) for full behavior,
limitations, artwork configuration, and tests.

## Configuration structure

- `wezterm.lua`: terminal settings and general keybindings.
- `colors/tron-legacy.lua`: terminal palette.
- `plugins/init.lua`: plugin switches and application order.
- `plugins/<name>/init.lua`: local plugin implementations or external-plugin wrappers.
- `plugins/sessions/picker.py`: fzf interface; Lua owns session state and workspace changes.
- `plugins/sessions/art.lua` and `art/`: animation settings and bundled artwork.

## Disabling or removing plugins

Disabling a plugin normally suffices. Smart Splits falls back to local pane
navigation, and Tabline falls back to a simple workspace/time status display.

To remove a downloaded external plugin, first disable every feature that depends
on it. For Resurrect, that includes Sessions as well as its standalone switch.
Use `wezterm.plugin.list()` in the debug overlay (`Ctrl+Shift+L`) to identify the
checkout, quit WezTerm, then delete only that plugin's directory. Local wrappers
and the Sessions implementation live in this configuration's `plugins/` folder.

## Integration notes

The Resurrect wrapper resolves modules from the StephenGemin checkout explicitly
when it is already installed, avoiding ambiguity with an older MLFlexer checkout.

Smart Splits needs `smart-splits.nvim` in Neovim for navigation between Neovim
windows and WezTerm panes. Without it, the WezTerm pane bindings still work.
On macOS, `Cmd+H/J/K/L` resizes WezTerm panes and forwards `Option+H/J/K/L`
to Neovim, matching the Neovim resize mappings.

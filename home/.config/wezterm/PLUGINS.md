# WezTerm plugins

Plugin switches live in `plugins/init.lua`. Change a switch, then press
`Cmd+Shift+R` to reload the configuration.

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
| Picker | `Enter` | Open, restore, or create the selected session |
| Picker | `Ctrl+T` | Toggle the session preview on the right |
| Picker | `Ctrl+R` | Rename the selected session |
| Picker | `Ctrl+X` | Confirm deletion of its saved layout and running terminals |
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
Restoring after a restart rebuilds the layout with fresh shells: it does not
resume programs, recover unsaved editor content, or restore terminal scrollback.
Shell history is managed separately by your shell.

State is stored as plaintext JSON at
`$XDG_STATE_HOME/wezterm/sessions/index.json`, defaulting to
`~/.local/state/wezterm/sessions/index.json`. Each save atomically replaces the
latest state; there are no rotating historical backups. Changes since the last
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

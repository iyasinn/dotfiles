# WezTerm plugins

All plugin switches live at the top of `plugins/init.lua`. Change a plugin from
`true` to `false`, then press `Cmd+Shift+R`, to disable it without editing the
main configuration.
Disabling Resurrect also hides Sessionizer's saved-state deletion entry and shortcut.

## Shortcuts

| Plugin | Shortcut | Action |
| --- | --- | --- |
| Smart Splits | `Ctrl+H/J/K/L` | Move between WezTerm and Neovim splits |
| Smart Splits | `Super+H/J/K/L` | Resize splits |
| Sessionizer | `Ctrl+A`, then `s` | Session menu: switch, create, delete saved state, help |
| Sessionizer | `Ctrl+A`, then `c` | Create a named session from the current directory |
| Sessionizer | `Ctrl+A`, then `p` | Fuzzy-pick a git project and create/switch session |
| Sessionizer | `Ctrl+A`, then `d` | Delete saved session state |
| Sessionizer | `Ctrl+A`, then `?` | Show WezTerm key bindings |
| Command Picker | `Ctrl+A`, then `Space` | Search all commands and shortcuts |
| Resurrect | `Option+Shift+N` | Create workspace |
| Resurrect | `Option+W` | Save workspace |
| Resurrect | `Option+S` | Save workspace and window |
| Resurrect | `Option+Shift+W` | Name and save window |
| Resurrect | `Option+Shift+T` | Name and save tab |
| Resurrect | `Option+R` | Restore saved state |
| Resurrect | `Option+D` | Delete saved state |

Note: deleting saved state removes the resurrected/persisted session file. It does
not close a currently running WezTerm workspace; live workspaces disappear when
their windows/tabs are closed or moved away from.

Tabline runs automatically and displays the workspace, tab index, process,
zoom status, and time. It preserves the main config's padding and tab width.

## Removing plugins

Disabling a plugin is normally enough. To also remove its downloaded files:

1. Disable it in `plugins/init.lua` and reload WezTerm.
2. Open the debug overlay with `Ctrl+Shift+L`.
3. Run `wezterm.plugin.list()` in the Lua REPL to find its directory.
4. Quit WezTerm and delete only that plugin directory.

`Awesome WezTerm` is a directory of plugins, not an installable plugin:
https://github.com/michaelbrusegard/awesome-wezterm

## Notes

Project sessions use their full directory path as the workspace name so projects
with the same folder name stay separate. The picker abbreviates your home directory
as `~`. Existing sessions with short names remain available in the session menu.

The Resurrect wrapper resolves modules from the StephenGemin checkout explicitly,
so an older installed MLFlexer checkout cannot interfere with config loading.

Smart Splits needs `smart-splits.nvim` installed in Neovim to move seamlessly
between Neovim windows and WezTerm panes. Without the Neovim half, the WezTerm
pane bindings still work.
On macOS, `Cmd+H/J/K/L` resizes WezTerm panes and forwards `Option+H/J/K/L`
to Neovim, matching the Neovim resize mappings.

Resurrect saves terminal state and visible terminal output as plaintext under
the standard WezTerm data directory unless its optional encryption is enabled.

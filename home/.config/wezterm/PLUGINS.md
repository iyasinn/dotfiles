# WezTerm plugins

All plugin switches live at the top of `plugins/init.lua`. Change a plugin from
`true` to `false`, then press `Cmd+Shift+R`, to disable it without editing the
main configuration.

## Shortcuts

| Plugin | Shortcut | Action |
| --- | --- | --- |
| Smart Splits | `Ctrl+H/J/K/L` | Move between WezTerm and Neovim splits |
| Smart Splits | `Super+H/J/K/L` | Resize splits |
| Sessionizer | `Ctrl+A`, then `s` | Search projects and workspaces |
| Command Picker | `Ctrl+A`, then `Space` | Search all commands and shortcuts |
| Resurrect | `Option+Shift+N` | Create workspace |
| Resurrect | `Option+W` | Save workspace |
| Resurrect | `Option+S` | Save workspace and window |
| Resurrect | `Option+Shift+W` | Name and save window |
| Resurrect | `Option+Shift+T` | Name and save tab |
| Resurrect | `Option+R` | Restore saved state |
| Resurrect | `Option+D` | Delete saved state |

Tabline runs automatically and displays the active mode, workspace, process,
time, and domain.

## Removing plugins

Disabling a plugin is normally enough. To also remove its downloaded files:

1. Disable it in `plugins/init.lua` and reload WezTerm.
2. Open the debug overlay with `Ctrl+Shift+L`.
3. Run `wezterm.plugin.list()` in the Lua REPL to find its directory.
4. Quit WezTerm and delete only that plugin directory.

`Awesome WezTerm` is a directory of plugins, not an installable plugin:
https://github.com/michaelbrusegard/awesome-wezterm

## Notes

Smart Splits needs `smart-splits.nvim` installed in Neovim to move seamlessly
between Neovim windows and WezTerm panes. Without the Neovim half, the WezTerm
pane bindings still work.

Resurrect saves terminal state and visible terminal output as plaintext under
the standard WezTerm data directory unless its optional encryption is enabled.

-- ─────────────────────────────────────────────────────────────
--  TRON: LEGACY — hand-tuned, no dependencies
-- ─────────────────────────────────────────────────────────────
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.termguicolors = true
vim.g.colors_name = "tron-legacy"

local c = {
  -- the void
  bg = "#05080d",
  bg1 = "#0b121c", -- panels, statusline, cursorline
  bg2 = "#122031", -- selection, folds
  bg3 = "#1a2c42", -- stronger surfaces, pmenu selection
  grid = "#22374f", -- borders, window separators
  -- the steel ramp
  ghost = "#2c4257", -- whitespace chars, deep-dim
  dim = "#3d5a73", -- comments, line numbers
  muted = "#6a8caa", -- punctuation, secondary UI
  fg = "#b8cfe0", -- body text
  bright = "#d5e9f5",
  halo = "#f2feff", -- suit-white
  -- the light
  cyan = "#5fd7ff", -- hero: functions, cursor, focus
  cyan_dp = "#2aa8d0", -- deep cyan: builtins, links
  frost = "#a8ecff", -- ice: definitions-at-peak, search fg
  teal = "#4fd6be", -- strings
  teal_dm = "#37907f", -- string delimiters, quiet green
  violet = "#a48cff", -- keywords
  vio_dm = "#7a6bc4", -- operators-adjacent, secondary kw
  -- the heat (scarce, by design)
  orange = "#ff9e3d", -- numbers, constants — Clu
  amber = "#e6b455", -- types
  heat = "#ff5f45", -- errors
  ember = "#d1704f", -- deprecated, deletes
}

local hl = function(g, o)
  vim.api.nvim_set_hl(0, g, o)
end

-- ── Editor chrome ─────────────────────────────────────────────
hl("Normal", { fg = c.fg, bg = c.bg })
hl("NormalFloat", { fg = c.fg, bg = c.bg1 })
hl("FloatBorder", { fg = c.cyan_dp, bg = c.bg1 })
hl("FloatTitle", { fg = c.cyan, bg = c.bg1, bold = true })
hl("WinSeparator", { fg = c.grid })
hl("CursorLine", { bg = c.bg1 })
hl("CursorColumn", { bg = c.bg1 })
hl("ColorColumn", { bg = c.bg1 })
hl("LineNr", { fg = c.ghost })
hl("CursorLineNr", { fg = c.cyan, bold = true })
hl("SignColumn", { bg = c.bg })
hl("Folded", { fg = c.muted, bg = c.bg2 })
hl("FoldColumn", { fg = c.dim })
hl("Visual", { bg = c.bg2 })
hl("VisualNOS", { bg = c.bg2 })
hl("Search", { fg = c.bg, bg = c.amber })
hl("IncSearch", { fg = c.bg, bg = c.cyan, bold = true })
hl("CurSearch", { fg = c.bg, bg = c.frost, bold = true })
hl("MatchParen", { fg = c.frost, bg = c.bg3, bold = true })
hl("Whitespace", { fg = c.ghost })
hl("NonText", { fg = c.ghost })
hl("EndOfBuffer", { fg = c.bg })
hl("StatusLine", { fg = c.bright, bg = c.bg1 })
hl("StatusLineNC", { fg = c.dim, bg = c.bg1 })
hl("TabLine", { fg = c.dim, bg = c.bg1 })
hl("TabLineSel", { fg = c.cyan, bg = c.bg, bold = true })
hl("TabLineFill", { bg = c.bg1 })
hl("Pmenu", { fg = c.fg, bg = c.bg1 })
hl("PmenuSel", { fg = c.bg, bg = c.cyan, bold = true })
hl("PmenuSbar", { bg = c.bg2 })
hl("PmenuThumb", { bg = c.cyan_dp })
hl("WildMenu", { fg = c.bg, bg = c.cyan })
hl("Title", { fg = c.cyan, bold = true })
hl("Directory", { fg = c.cyan_dp })
hl("ErrorMsg", { fg = c.heat, bold = true })
hl("WarningMsg", { fg = c.orange })
hl("MoreMsg", { fg = c.teal })
hl("Question", { fg = c.cyan })
hl("QuickFixLine", { bg = c.bg2, bold = true })

-- ── Core syntax ───────────────────────────────────────────────
hl("Comment", { fg = c.dim, italic = true })
hl("String", { fg = c.teal })
hl("Character", { fg = c.teal })
hl("Number", { fg = c.orange })
hl("Float", { fg = c.orange })
hl("Boolean", { fg = c.orange })
hl("Constant", { fg = c.orange })
hl("Identifier", { fg = c.fg })
hl("Function", { fg = c.cyan })
hl("Statement", { fg = c.violet })
hl("Keyword", { fg = c.violet, italic = true })
hl("Conditional", { fg = c.violet, italic = true })
hl("Repeat", { fg = c.violet, italic = true })
hl("Label", { fg = c.vio_dm })
hl("Operator", { fg = c.muted })
hl("Exception", { fg = c.heat })
hl("PreProc", { fg = c.vio_dm })
hl("Include", { fg = c.vio_dm, italic = true })
hl("Define", { fg = c.vio_dm })
hl("Macro", { fg = c.cyan_dp })
hl("Type", { fg = c.amber })
hl("StorageClass", { fg = c.violet })
hl("Structure", { fg = c.amber })
hl("Typedef", { fg = c.amber })
hl("Special", { fg = c.cyan_dp })
hl("SpecialChar", { fg = c.frost })
hl("Delimiter", { fg = c.muted })
hl("Underlined", { fg = c.cyan_dp, underline = true })
hl("Error", { fg = c.heat, bold = true })
hl("Todo", { fg = c.bg, bg = c.orange, bold = true })

-- ── Treesitter: where the detail lives ────────────────────────
hl("@variable", { fg = c.fg })
hl("@variable.builtin", { fg = c.frost, italic = true }) -- self, this
hl("@variable.parameter", { fg = c.bright, italic = true })
hl("@variable.member", { fg = c.fg })
hl("@property", { fg = c.fg })
hl("@field", { fg = c.fg })
hl("@function", { fg = c.cyan })
hl("@function.builtin", { fg = c.cyan_dp })
hl("@function.call", { fg = c.cyan })
hl("@function.method", { fg = c.cyan })
hl("@constructor", { fg = c.amber })
hl("@keyword", { fg = c.violet, italic = true })
hl("@keyword.function", { fg = c.violet, italic = true })
hl("@keyword.return", { fg = c.violet, bold = true }) -- returns pop
hl("@keyword.operator", { fg = c.vio_dm })
hl("@type", { fg = c.amber })
hl("@type.builtin", { fg = c.amber, italic = true })
hl("@string", { fg = c.teal })
hl("@string.escape", { fg = c.frost })
hl("@string.regexp", { fg = c.cyan_dp })
hl("@number", { fg = c.orange })
hl("@boolean", { fg = c.orange })
hl("@constant", { fg = c.orange })
hl("@constant.builtin", { fg = c.orange, italic = true })
hl("@operator", { fg = c.muted })
hl("@punctuation.bracket", { fg = c.muted })
hl("@punctuation.delimiter", { fg = c.muted })
hl("@punctuation.special", { fg = c.cyan_dp })
hl("@tag", { fg = c.violet })
hl("@tag.attribute", { fg = c.cyan_dp })
hl("@tag.delimiter", { fg = c.muted })
hl("@comment.todo", { fg = c.bg, bg = c.orange, bold = true })
hl("@comment.error", { fg = c.bg, bg = c.heat, bold = true })
hl("@comment.warning", { fg = c.bg, bg = c.amber, bold = true })
hl("@comment.note", { fg = c.bg, bg = c.cyan, bold = true })
hl("@markup.heading", { fg = c.cyan, bold = true })
hl("@markup.strong", { fg = c.bright, bold = true })
hl("@markup.italic", { italic = true })
hl("@markup.link", { fg = c.cyan_dp, underline = true })
hl("@markup.raw", { fg = c.teal_dm })
hl("@markup.list", { fg = c.violet })

-- ── LSP semantic tokens (defer to Treesitter styling) ─────────
hl("@lsp.type.function", { link = "@function" })
hl("@lsp.type.method", { link = "@function.method" })
hl("@lsp.type.parameter", { link = "@variable.parameter" })
hl("@lsp.type.property", { link = "@property" })
hl("@lsp.type.variable", { link = "@variable" })

-- ── Diagnostics ───────────────────────────────────────────────
hl("DiagnosticError", { fg = c.heat })
hl("DiagnosticWarn", { fg = c.orange })
hl("DiagnosticInfo", { fg = c.cyan_dp })
hl("DiagnosticHint", { fg = c.teal_dm })
hl("DiagnosticUnderlineError", { undercurl = true, sp = c.heat })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.orange })
hl("DiagnosticUnderlineInfo", { undercurl = true, sp = c.cyan_dp })
hl("DiagnosticUnderlineHint", { undercurl = true, sp = c.teal_dm })
hl("DiagnosticVirtualTextError", { fg = c.heat, bg = "#1a0e0d" })
hl("DiagnosticVirtualTextWarn", { fg = c.orange, bg = "#1a140a" })
hl("DiagnosticVirtualTextInfo", { fg = c.cyan_dp, bg = c.bg1 })
hl("DiagnosticVirtualTextHint", { fg = c.teal_dm, bg = c.bg1 })
hl("LspReferenceText", { bg = c.bg2 })
hl("LspReferenceRead", { bg = c.bg2 })
hl("LspReferenceWrite", { bg = c.bg3 })
hl("LspInlayHint", { fg = c.ghost, italic = true })

-- ── Git ───────────────────────────────────────────────────────
hl("DiffAdd", { bg = "#0c1f1a" })
hl("DiffChange", { bg = "#0d1a26" })
hl("DiffDelete", { fg = c.ember, bg = "#1a0e0d" })
hl("DiffText", { bg = "#14304a" })
hl("Added", { fg = c.teal })
hl("Changed", { fg = c.cyan_dp })
hl("Removed", { fg = c.ember })
hl("GitSignsAdd", { fg = c.teal_dm })
hl("GitSignsChange", { fg = c.cyan_dp })
hl("GitSignsDelete", { fg = c.ember })

-- ── Plugin UI ─────────────────────────────────────────────────
hl("TelescopeBorder", { fg = c.grid, bg = c.bg })
hl("TelescopePromptBorder", { fg = c.cyan_dp, bg = c.bg })
hl("TelescopeTitle", { fg = c.cyan, bold = true })
hl("TelescopeSelection", { bg = c.bg2 })
hl("TelescopeMatching", { fg = c.frost, bold = true })
hl("CmpItemAbbrMatch", { fg = c.cyan, bold = true })
hl("CmpItemAbbrMatchFuzzy", { fg = c.cyan })
hl("CmpItemKindFunction", { fg = c.cyan })
hl("CmpItemKindKeyword", { fg = c.violet })
hl("CmpItemKindVariable", { fg = c.fg })
hl("CmpItemKindClass", { fg = c.amber })
hl("BlinkCmpLabelMatch", { fg = c.cyan, bold = true })
hl("WhichKey", { fg = c.cyan })
hl("WhichKeyGroup", { fg = c.violet })
hl("WhichKeyDesc", { fg = c.fg })
hl("IblIndent", { fg = c.bg2 })
hl("IblScope", { fg = c.grid })
hl("SnacksIndent", { fg = c.bg2 })
hl("SnacksIndentScope", { fg = c.grid })
hl("NoiceCmdlinePopupBorder", { fg = c.cyan_dp })
hl("NotifyINFOIcon", { fg = c.cyan })
hl("NotifyINFOTitle", { fg = c.cyan })
hl("NotifyERRORIcon", { fg = c.heat })
hl("NotifyERRORTitle", { fg = c.heat })
hl("NotifyWARNIcon", { fg = c.orange })
hl("NotifyWARNTitle", { fg = c.orange })

-- ── Terminal palette inside :terminal ─────────────────────────
vim.g.terminal_color_0 = c.bg1
vim.g.terminal_color_8 = c.dim
vim.g.terminal_color_1 = c.heat
vim.g.terminal_color_9 = "#ff8266"
vim.g.terminal_color_2 = c.teal
vim.g.terminal_color_10 = "#7ce8d4"
vim.g.terminal_color_3 = c.amber
vim.g.terminal_color_11 = "#f2cd80"
vim.g.terminal_color_4 = c.cyan
vim.g.terminal_color_12 = c.frost
vim.g.terminal_color_5 = c.violet
vim.g.terminal_color_13 = "#c3b2ff"
vim.g.terminal_color_6 = c.cyan_dp
vim.g.terminal_color_14 = "#9fdcef"
vim.g.terminal_color_7 = c.fg
vim.g.terminal_color_15 = c.halo

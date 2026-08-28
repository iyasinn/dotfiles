bindkey -v
bindkey '^?' backward-delete-char
# TODO: Consider moving shell exports/settings into ~/.config/zsh/exports.zsh later.
export KEYTIMEOUT=10

# TODO: Could live in ~/.config/zsh/exports.zsh if you want a cleaner .zshrc.
export EDITOR=nvim
export VISUAL=nvim



# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ----- Zinit (manages all plugins) -----
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"

# ----- Plugins: autocomplete (keep early) -----
# TODO: Remove this whole commented autocomplete block if you do not plan to use it.
# TODO: If re-enabling, these zstyle lines likely need a space after `zstyle`.
# zstyle':autocomplete:*' min-input 1     # start listing after 1 character
# zstyle':autocomplete:*' delay 0.05      # seconds before the list appears
# zinit light marlonrichert/zsh-autocomplete

# ----- Aliases -----
# TODO: Consider moving aliases into ~/.config/zsh/aliases.zsh later.
alias lg='lazygit'
alias dotf='cd ~/anvil/dotfiles/ && nvim .'

# ----- Secrets (kept out of the dotfiles repo, chmod 600) -----
# TODO: Make sure ~/.config/zsh/secrets.zsh is never committed if it contains tokens/API keys.
[[ -f "$HOME/.config/zsh/secrets.zsh" ]] && source "$HOME/.config/zsh/secrets.zsh"

# ----- Java -----
# TODO: Remove this hardcoded Java block if you do not actively need Java 21 globally.
# TODO: If you want Java version management later, consider moving Java to mise too.
if /usr/libexec/java_home -v 21 >/dev/null 2>&1; then
  export JAVA_HOME=$(/usr/libexec/java_home -v 21)
  export PATH="$JAVA_HOME/bin:$PATH"
fi

# ----- Add .local/bin to our path -----
# TODO: Keep this if you use personal scripts like ~/.local/bin/entire or ~/.local/bin/herdr.
# TODO: If not using personal scripts, this block is optional.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# ----- Prompt: Powerlevel10k + Catppuccin preset -----
# zstyle settings must come BEFORE the Catppuccin plugin loads
zstyle ':catppuccin:p10k' 'theme' 'classic'
zstyle ':catppuccin:p10k' 'flavour' 'mocha'
zinit light romkatv/powerlevel10k
zinit light tolkonepiu/catppuccin-powerlevel10k-themes
# TODO: You have ~/.config/zsh/p10k.zsh, but it is not sourced right now.
# TODO: If you want to use it, add:
# [[ -f "$HOME/.config/zsh/p10k.zsh" ]] && source "$HOME/.config/zsh/p10k.zsh"

# ----- Syntax highlighting (must stay last) -----
zinit light zsh-users/zsh-syntax-highlighting

# ----- mise -----
# Runtime/tool version manager. Replaces pyenv/nvm/asdf-style setup.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi



# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r '/Users/iyasin/.opam/opam-init/init.zsh' ]] || source '/Users/iyasin/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null
# END opam configuration
